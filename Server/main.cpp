#define CROW_MAIN
#include "crow_all.h"
#include "json.hpp"

#include <fstream>
#include <mutex>
#include <string>
#include <filesystem>
#include <chrono>
#include <sstream>
#include <iomanip>
#include <algorithm>
#include <vector>

using json = nlohmann::json;
namespace fs = std::filesystem;

// ─── Config ───────────────────────────────────────────────────────────────────
std::string DATA_DIR  = "inventories";
std::string META_FILE = "inventories_meta.json";
std::mutex  g_mutex;

const size_t MAX_BACKUPS = 20;

// ─── Helpers ──────────────────────────────────────────────────────────────────
std::string inv_path(const std::string& id) { return DATA_DIR + "/" + id + ".json"; }

std::string now_iso() {
    auto now = std::chrono::system_clock::now();
    auto t   = std::chrono::system_clock::to_time_t(now);
    std::ostringstream ss;
    ss << std::put_time(std::gmtime(&t), "%Y-%m-%dT%H:%M:%SZ");
    return ss.str();
}

std::string now_safe_filename() {
    auto now = std::chrono::system_clock::now();
    auto t   = std::chrono::system_clock::to_time_t(now);
    std::ostringstream ss;
    ss << std::put_time(std::gmtime(&t), "%Y%m%d_%H%M%S");
    return ss.str();
}

std::string gen_id() {
    auto ns = std::chrono::system_clock::now().time_since_epoch().count();
    std::ostringstream ss;
    ss << std::hex << ns;
    return ss.str();
}

bool valid_id(const std::string& id) {
    if (id.empty() || id.size() > 64) return false;
    for (char c : id) if (!isalnum(c) && c != '-' && c != '_') return false;
    return true;
}

crow::response json_ok(const json& j, int code = 200) {
    crow::response r(code, j.dump());
    r.add_header("Content-Type", "application/json");
    return r;
}
// Like json_ok but also sends X-Last-Updated so clients can store the exact
// server timestamp and avoid false sync conflicts on next launch.
crow::response json_ok_ts(const json& j, const std::string& ts, int code = 200) {
    crow::response r(code, j.dump());
    r.add_header("Content-Type", "application/json");
    r.add_header("X-Last-Updated", ts);
    return r;
}
crow::response json_err(const std::string& msg, int code = 400) { return json_ok({{"error", msg}}, code); }

// ─── Meta ─────────────────────────────────────────────────────────────────────
json load_meta() {
    std::lock_guard<std::mutex> lk(g_mutex);
    if (!fs::exists(META_FILE)) return json::array();
    std::ifstream f(META_FILE);
    try { return json::parse(f); } catch (...) { return json::array(); }
}

void save_meta(const json& m) {
    std::lock_guard<std::mutex> lk(g_mutex);
    std::ofstream f(META_FILE);
    f << m.dump(2);
}

// ─── Inventario & Backup ──────────────────────────────────────────────────────
json load_inv(const std::string& id) {
    std::lock_guard<std::mutex> lk(g_mutex);
    const auto p = inv_path(id);
    if (!fs::exists(p)) return {
        {"components", json::array()},
        {"settings", {{"drawerRows",4}, {"drawerColumns",6}, {"availableTags",json::array()}, {"tagTree",json::object()}, {"specialTags",json::array()}}}
    };
    std::ifstream f(p);
    try { return json::parse(f); } catch (...) { return {{"components",json::array()},{"settings",json::object()}}; }
}

void backup_inv(const std::string& id, const json& db) {
    std::string backup_dir = DATA_DIR + "/backups";
    fs::create_directories(backup_dir);

    std::string backup_file = backup_dir + "/" + id + "_" + now_safe_filename() + ".json";
    std::ofstream f(backup_file);
    f << db.dump(2);
    f.close();

    std::vector<fs::path> backups;
    std::string prefix = id + "_";
    
    for (const auto& entry : fs::directory_iterator(backup_dir)) {
        if (entry.is_regular_file()) {
            std::string filename = entry.path().filename().string();
            if (filename.find(prefix) == 0 && filename.find(".json") != std::string::npos) {
                backups.push_back(entry.path());
            }
        }
    }

    std::sort(backups.begin(), backups.end());
    while (backups.size() > MAX_BACKUPS) {
        fs::remove(backups.front());
        backups.erase(backups.begin());
    }
}

// Returns the lastUpdated timestamp that was written, so callers can echo
// it back to clients via X-Last-Updated, preventing false sync conflicts.
std::string save_inv(const std::string& id, json& db) {
    std::lock_guard<std::mutex> lk(g_mutex);
    std::string ts = now_iso();
    db["lastUpdated"] = ts;
    fs::create_directories(DATA_DIR);
    std::ofstream f(inv_path(id));
    f << db.dump(2);
    f.close();
    return ts;
}

// ─── CORS ─────────────────────────────────────────────────────────────────────
struct CORS {
    struct context {};
    void before_handle(crow::request&, crow::response& res, context&) {
        res.add_header("Access-Control-Allow-Origin",  "*");
        res.add_header("Access-Control-Allow-Methods", "GET,POST,PUT,PATCH,DELETE,OPTIONS");
        res.add_header("Access-Control-Allow-Headers", "Content-Type");
    }
    void after_handle(crow::request&, crow::response& res, context&) { res.add_header("Access-Control-Allow-Origin", "*"); }
};

// ─── Main ─────────────────────────────────────────────────────────────────────
int main(int argc, char* argv[]) {
    uint16_t port = 8080;
    if (argc >= 2) port = static_cast<uint16_t>(std::stoi(argv[1]));
    if (argc >= 3) DATA_DIR = argv[2];

    fs::create_directories(DATA_DIR);
    fs::create_directories(DATA_DIR + "/backups");

    crow::App<CORS> app;

    CROW_ROUTE(app, "/<path>").methods("OPTIONS"_method)
    ([](const crow::request&, crow::response& res, const std::string&) { res.code = 204; res.end(); });

    CROW_ROUTE(app, "/api/status").methods("GET"_method)
    ([]() { return json_ok({{"status","ok"},{"server","inventory-multi"},{"version","2.0"}}); });

    // ── Updates ──
    CROW_ROUTE(app, "/api/update/version").methods("GET"_method)
    ([]() {
        std::ifstream f("version.txt");
        std::string v; if (f) f >> v; else v = "1.0.0";
        return json_ok({{"version", v}});
    });

    CROW_ROUTE(app, "/api/update/download").methods("GET"_method)
    ([](crow::response& res) {
        std::string apk_file = "";
        
        // Cerca il primo file .apk nella directory corrente
        for (const auto& entry : fs::directory_iterator(".")) {
            if (entry.is_regular_file() && entry.path().extension() == ".apk") {
                apk_file = entry.path().filename().string();
                break;
            }
        }

        if (!apk_file.empty()) {
            res.set_static_file_info(apk_file);
        } else {
            res.code = 404;
            res.body = "{\"error\": \"APK non trovato\"}";
            res.add_header("Content-Type", "application/json");
        }
        res.end();
    });

    // ── Backups ──
    CROW_ROUTE(app, "/api/inventories/<string>/backups").methods("GET"_method)
    ([](const std::string& inv) {
        if (!valid_id(inv)) return json_err("ID non valido");
        std::vector<std::string> res;
        std::string prefix = inv + "_";
        std::string dir = DATA_DIR + "/backups";
        if (fs::exists(dir)) {
            for (const auto& entry : fs::directory_iterator(dir)) {
                std::string fn = entry.path().filename().string();
                if (fn.find(prefix) == 0) res.push_back(fn);
            }
        }
        std::sort(res.rbegin(), res.rend()); 
        return json_ok(res);
    });

    CROW_ROUTE(app, "/api/inventories/<string>/backups/<string>/restore").methods("POST"_method)
    ([](const std::string& inv, const std::string& filename) {
        if (!valid_id(inv)) return json_err("ID non valido");
        fs::path p = fs::path(DATA_DIR) / "backups" / filename;
        if (!fs::exists(p)) return json_err("Backup non trovato", 404);
        try {
            std::ifstream f(p);
            auto db = json::parse(f);
            auto ts = save_inv(inv, db);
            return json_ok_ts({{"restored", true}}, ts);
        } catch (const std::exception& e) { return json_err(e.what()); }
    });

    // ── Inventari ──
    CROW_ROUTE(app, "/api/inventories").methods("GET"_method)
    ([]() { return json_ok(load_meta()); });

    CROW_ROUTE(app, "/api/inventories").methods("POST"_method)
    ([](const crow::request& req) {
        try {
            auto body = json::parse(req.body);
            const std::string name = body.value("name", "Nuovo inventario");
            const std::string desc = body.value("description", "");
            const std::string id   = body.contains("id") ? body["id"].get<std::string>() : gen_id();

            if (!valid_id(id)) return json_err("ID non valido");
            auto meta = load_meta();
            for (const auto& m : meta) if (m["id"] == id) return json_err("ID già esistente", 409);

            json entry = {{"id",id},{"name",name},{"description",desc}, {"createdAt",now_iso()}};
            meta.push_back(entry);
            save_meta(meta);

            json empty = {{"components", json::array()}, {"settings", {{"drawerRows",4},{"drawerColumns",6}, {"availableTags",json::array()}, {"tagTree",json::object()}, {"specialTags",json::array()}}}};
            save_inv(id, empty);
            return json_ok(entry, 201);
        } catch (const std::exception& e) { return json_err(e.what()); }
    });

    CROW_ROUTE(app, "/api/inventories/<string>").methods("PUT"_method)
    ([](const crow::request& req, const std::string& id) {
        if (!valid_id(id)) return json_err("ID non valido");
        try {
            auto body = json::parse(req.body);
            auto meta = load_meta();
            for (auto& m : meta) {
                if (m["id"] == id) {
                    if (body.contains("name"))        m["name"]        = body["name"];
                    if (body.contains("description")) m["description"] = body["description"];
                    save_meta(meta);
                    return json_ok(m);
                }
            }
            return json_err("Non trovato", 404);
        } catch (const std::exception& e) { return json_err(e.what()); }
    });

    CROW_ROUTE(app, "/api/inventories/<string>").methods("DELETE"_method)
    ([](const std::string& id) {
        if (!valid_id(id)) return json_err("ID non valido");
        auto meta = load_meta();
        auto prev = meta.size();
        meta.erase(std::remove_if(meta.begin(), meta.end(), [&](const json& m){ return m["id"] == id; }), meta.end());
        if (meta.size() == prev) return json_err("Non trovato", 404);
        save_meta(meta);
        const auto p = inv_path(id);
        if (fs::exists(p)) fs::remove(p);
        return json_ok({{"deleted", id}});
    });

    // ── Ricerca Globale ──
    CROW_ROUTE(app, "/api/search").methods("GET"_method)
    ([](const crow::request& req) {
        std::string q = req.url_params.get("q") ? req.url_params.get("q") : "";
        auto to_lower = [](std::string s) {
            std::transform(s.begin(), s.end(), s.begin(), [](unsigned char c){ return std::tolower(c); });
            return s;
        };
        std::string query = to_lower(q);
        
        json results = json::array();
        if (query.empty()) return json_ok(results);

        auto meta = load_meta();
        for (const auto& inv : meta) {
            std::string inv_id = inv.value("id", "");
            std::string inv_name = inv.value("name", "");
            if (inv_id.empty()) continue;
            
            auto db = load_inv(inv_id);
            if (!db.contains("components") || !db["components"].is_array()) continue;
            
            for (const auto& comp : db["components"]) {
                bool match = false;
                std::string cname = to_lower(comp.value("name", ""));
                std::string cdesc = to_lower(comp.value("description", ""));
                
                if (cname.find(query) != std::string::npos || cdesc.find(query) != std::string::npos) {
                    match = true;
                } else if (comp.contains("tags") && comp["tags"].is_array()) {
                    for (const auto& t : comp["tags"]) {
                        std::string tstr = to_lower(t.get<std::string>());
                        if (tstr.find(query) != std::string::npos) { match = true; break; }
                    }
                }
                
                if (match) {
                    json res_item;
                    res_item["inventoryId"] = inv_id;
                    res_item["inventoryName"] = inv_name;
                    res_item["component"] = comp;
                    results.push_back(res_item);
                }
            }
        }
        return json_ok(results);
    });

    // ── Componenti ──
    CROW_ROUTE(app, "/api/inventories/<string>/components").methods("GET"_method)
    ([](const std::string& inv) {
        if (!valid_id(inv)) return json_err("ID inventario non valido");
        return json_ok(load_inv(inv)["components"]);
    });

    CROW_ROUTE(app, "/api/inventories/<string>/components").methods("POST"_method)
    ([](const crow::request& req, const std::string& inv) {
        if (!valid_id(inv)) return json_err("ID inventario non valido");
        try {
            auto body = json::parse(req.body);
            if (!body.contains("id")||!body.contains("name")||!body.contains("drawer")) return json_err("Obbligatori: id, name, drawer");
            auto db = load_inv(inv);
            for (const auto& c : db["components"]) if (c["id"] == body["id"]) return json_err("ID già esistente", 409);
            db["components"].push_back(body);
            auto ts = save_inv(inv, db);
            return json_ok_ts(body, ts, 201);
        } catch (const std::exception& e) { return json_err(e.what()); }
    });

    CROW_ROUTE(app, "/api/inventories/<string>/components/<string>").methods("PUT"_method)
    ([](const crow::request& req, const std::string& inv, const std::string& id) {
        if (!valid_id(inv)) return json_err("ID inventario non valido");
        try {
            auto body = json::parse(req.body);
            auto db = load_inv(inv);
            for (auto& c : db["components"]) {
                if (c["id"] == id) {
                    body["id"] = id;
                    c = body;
                    auto ts = save_inv(inv, db);
                    return json_ok_ts(c, ts);
                }
            }
            return json_err("Non trovato", 404);
        } catch (const std::exception& e) { return json_err(e.what()); }
    });

    CROW_ROUTE(app, "/api/inventories/<string>/components/<string>/quantity").methods("PATCH"_method)
    ([](const crow::request& req, const std::string& inv, const std::string& id) {
        if (!valid_id(inv)) return json_err("ID inventario non valido");
        try {
            auto body = json::parse(req.body);
            auto db = load_inv(inv);
            for (auto& c : db["components"]) {
                if (c["id"] == id) {
                    int cur = c["quantity"].get<int>();
                    if (body.contains("delta")) c["quantity"] = std::max(0, cur + body["delta"].get<int>());
                    else if (body.contains("quantity")) c["quantity"] = std::max(0, body["quantity"].get<int>());
                    auto ts = save_inv(inv, db);
                    return json_ok_ts(c, ts);
                }
            }
            return json_err("Non trovato", 404);
        } catch (const std::exception& e) { return json_err(e.what()); }
    });

    CROW_ROUTE(app, "/api/inventories/<string>/components/<string>").methods("DELETE"_method)
    ([](const std::string& inv, const std::string& id) {
        if (!valid_id(inv)) return json_err("ID inventario non valido");
        auto db = load_inv(inv);
        auto& cs = db["components"];
        auto prev = cs.size();
        cs.erase(std::remove_if(cs.begin(), cs.end(), [&](const json& c){ return c["id"] == id; }), cs.end());
        if (cs.size() == prev) return json_err("Non trovato", 404);
        auto ts = save_inv(inv, db);
        return json_ok_ts({{"deleted", id}}, ts);
    });

    // ── Attachments ──
    CROW_ROUTE(app, "/api/inventories/<string>/attachments").methods("POST"_method)
    ([](const crow::request& req, const std::string& inv) {
        if (!valid_id(inv)) return json_err("ID inventario non valido");
        std::string filename = req.get_header_value("X-Filename");
        if (filename.empty()) filename = "attachment.bin";
        
        std::string safe_filename = gen_id() + "_" + filename;
        std::string attach_dir = DATA_DIR + "/attachments/" + inv;
        fs::create_directories(attach_dir);
        
        std::string path = attach_dir + "/" + safe_filename;
        std::ofstream out(path, std::ios::binary);
        out.write(req.body.data(), req.body.size());
        out.close();
        
        return json_ok({{"filename", safe_filename}, {"originalName", filename}});
    });

    CROW_ROUTE(app, "/api/inventories/<string>/attachments/<path>").methods("GET"_method)
    ([](crow::response& res, const std::string& inv, const std::string& filename) {
        if (!valid_id(inv)) { res.code = 400; res.end(); return; }
        if (filename.find("..") != std::string::npos || filename.find('/') != std::string::npos) {
            res.code = 400; res.end(); return; 
        }
        std::string path = DATA_DIR + "/attachments/" + inv + "/" + filename;
        std::ifstream in(path, std::ios::binary);
        if (!in) {
            res.code = 404; res.end(); return;
        }
        std::ostringstream contents;
        contents << in.rdbuf();
        res.body = contents.str();
        
        // Basic MIME type detection
        std::string ext = "";
        auto pos = filename.find_last_of('.');
        if (pos != std::string::npos) {
            ext = filename.substr(pos);
            for (auto& c : ext) c = tolower(c);
        }
        if (ext == ".pdf") res.add_header("Content-Type", "application/pdf");
        else if (ext == ".png") res.add_header("Content-Type", "image/png");
        else if (ext == ".jpg" || ext == ".jpeg") res.add_header("Content-Type", "image/jpeg");
        else res.add_header("Content-Type", "application/octet-stream");

        res.add_header("Content-Disposition", "inline; filename=\"" + filename + "\"");
        res.end();
    });

    CROW_ROUTE(app, "/api/inventories/<string>/attachments/<path>").methods("DELETE"_method)
    ([](const std::string& inv, const std::string& filename) {
        if (!valid_id(inv)) return json_err("ID inventario non valido");
        if (filename.find("..") != std::string::npos || filename.find('/') != std::string::npos) {
            return json_err("Nome file non valido", 400);
        }
        std::string path = DATA_DIR + "/attachments/" + inv + "/" + filename;
        if (fs::exists(path)) {
            fs::remove(path);
        }
        return json_ok({{"deleted", true}});
    });

    // ── Settings ──
    CROW_ROUTE(app, "/api/inventories/<string>/settings").methods("GET"_method)
    ([](const std::string& inv) {
        if (!valid_id(inv)) return json_err("ID inventario non valido");
        return json_ok(load_inv(inv)["settings"]);
    });

    CROW_ROUTE(app, "/api/inventories/<string>/settings").methods("PUT"_method)
    ([](const crow::request& req, const std::string& inv) {
        if (!valid_id(inv)) return json_err("ID inventario non valido");
        try {
            auto db = load_inv(inv);
            db["settings"] = json::parse(req.body);
            auto ts = save_inv(inv, db);
            return json_ok_ts(db["settings"], ts);
        } catch (const std::exception& e) { return json_err(e.what()); }
    });

    // ── Full DB ──
    CROW_ROUTE(app, "/api/inventories/<string>/db").methods("GET"_method)
    ([](const std::string& inv) {
        if (!valid_id(inv)) return json_err("ID inventario non valido");
        auto db = load_inv(inv);
        crow::response res(200, db.dump(2));
        res.add_header("Content-Type", "application/json");
        res.add_header("Content-Disposition", "attachment; filename=\"inventario_" + inv + ".json\"");
        return res;
    });

    CROW_ROUTE(app, "/api/inventories/<string>/db").methods("POST"_method)
    ([](const crow::request& req, const std::string& inv) {
        if (!valid_id(inv)) return json_err("ID inventario non valido");
        try {
            auto body = json::parse(req.body);
            if (!body.contains("components") || !body.contains("settings")) return json_err("Obbligatori: components, settings");
            auto ts = save_inv(inv, body);
            return json_ok_ts({{"imported", true}, {"lastUpdated", ts}}, ts);
        } catch (const std::exception& e) { return json_err(e.what()); }
    });

    // Crea un backup manualmente
    CROW_ROUTE(app, "/api/inventories/<string>/backup").methods("POST"_method)
    ([](const std::string& inv) {
        if (!valid_id(inv)) return json_err("ID non valido");
        try {
            auto db = load_inv(inv);
            backup_inv(inv, db);
            return json_ok({{"backed_up", true}});
        } catch (const std::exception& e) { return json_err(e.what()); }
    });

    app.port(port).multithreaded().run();
    return 0;
}