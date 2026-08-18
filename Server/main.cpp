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
#include <regex>
#include <optional>
#include <unordered_map>

using json = nlohmann::json;
namespace fs = std::filesystem;

// ─── Config ───────────────────────────────────────────────────────────────────
std::string DATA_DIR  = "inventories";
std::string META_FILE = "inventories_meta.json";
std::mutex  g_mutex;

const size_t MAX_BACKUPS = 20;

// ─── Cache ────────────────────────────────────────────────────────────────────
std::optional<json> g_cached_meta;
std::unordered_map<std::string, json> g_cached_inventories;

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

std::string trim(std::string s) {
    s.erase(s.begin(), std::find_if(s.begin(), s.end(), [](unsigned char ch) {
        return !std::isspace(ch);
    }));
    s.erase(std::find_if(s.rbegin(), s.rend(), [](unsigned char ch) {
        return !std::isspace(ch);
    }).base(), s.end());
    return s;
}

double get_multiplier(const std::string& letter) {
    if (letter == "T" || letter == "t") return 1e12;
    if (letter == "G" || letter == "g") return 1e9;
    if (letter == "M") return 1e6;
    if (letter == "k" || letter == "K") return 1e3;
    if (letter == "m") return 1e-3;
    if (letter == "u" || letter == "U" || letter == "µ" || letter == "\xc2\xb5" || letter == "\xce\xbc") return 1e-6; 
    if (letter == "n" || letter == "N") return 1e-9;
    if (letter == "p" || letter == "P") return 1e-12;
    if (letter == "f" || letter == "F") return 1e-15;
    return 1.0;
}

std::optional<double> parse_special_value(const std::string& text) {
    std::string v = trim(text);
    std::replace(v.begin(), v.end(), ',', '.');
    if (v.empty()) return std::nullopt;

    try {
        size_t idx = 0;
        double direct = std::stod(v, &idx);
        if (idx == v.size()) {
            return direct;
        }
    } catch (...) {}

    std::regex reg1("^([0-9]+)([a-zA-Z]|\\xc2\\xb5|\\xce\\xbc)([0-9]*)$");
    std::smatch match1;
    if (std::regex_match(v, match1, reg1)) {
        std::string part1 = match1[1].str();
        std::string letter = match1[2].str();
        std::string part2 = match1[3].str();
        
        std::string num_str = part1 + "." + (part2.empty() ? "0" : part2);
        try {
            double base_num = std::stod(num_str);
            return base_num * get_multiplier(letter);
        } catch (...) {}
    }

    std::regex reg2("^([0-9]*\\.?[0-9]+)([a-zA-Z]|\\xc2\\xb5|\\xce\\xbc)$");
    std::smatch match2;
    if (std::regex_match(v, match2, reg2)) {
        std::string base_str = match2[1].str();
        std::string letter = match2[2].str();
        try {
            double base_num = std::stod(base_str);
            return base_num * get_multiplier(letter);
        } catch (...) {}
    }

    return std::nullopt;
}

struct ParsedQueryTerm {
    std::string term;
    std::optional<double> parsed_value;
    // Map of unit to (parsed_term_unit_stripped, term_matches_unit)
    std::unordered_map<std::string, std::pair<std::optional<double>, bool>> unit_matches;
};

bool matches_query(const json& comp, 
                   const std::vector<ParsedQueryTerm>& query_terms, 
                   const std::unordered_map<std::string, std::pair<bool, std::string>>& special_tags_map) {
    if (query_terms.empty()) return true;

    auto to_lower = [](std::string s) {
        std::transform(s.begin(), s.end(), s.begin(), [](unsigned char c){ return std::tolower(c); });
        return s;
    };

    std::string cname = to_lower(comp.value("name", ""));
    std::string cdesc = to_lower(comp.value("description", ""));
    std::string cdrawer = to_lower(comp.value("drawer", ""));
    std::string ccabinet = "";
    if (comp.contains("cabinet")) {
        if (comp["cabinet"].is_number()) {
            ccabinet = std::to_string(comp["cabinet"].get<int>());
        } else if (comp["cabinet"].is_string()) {
            ccabinet = to_lower(comp["cabinet"].get<std::string>());
        }
    }

    std::vector<std::string> ctags;
    if (comp.contains("tags") && comp["tags"].is_array()) {
        for (const auto& t : comp["tags"]) {
            if (t.is_string()) {
                ctags.push_back(to_lower(t.get<std::string>()));
            }
        }
    }

    auto term_matches = [&](const ParsedQueryTerm& pt) {
        if (cname.find(pt.term) != std::string::npos) return true;
        if (cdrawer.find(pt.term) != std::string::npos) return true;
        if (ccabinet.find(pt.term) != std::string::npos) return true;
        if (cdesc.find(pt.term) != std::string::npos) return true;
        
        for (const auto& t : ctags) {
            if (t.find(pt.term) != std::string::npos) return true;
        }

        if (comp.contains("specialTagValues") && comp["specialTagValues"].is_object()) {
            auto special_vals = comp["specialTagValues"];
            for (auto it = special_vals.begin(); it != special_vals.end(); ++it) {
                std::string key = it.key();
                bool is_str = false;
                std::string unit = "";
                
                auto it_tag = special_tags_map.find(key);
                if (it_tag != special_tags_map.end()) {
                    is_str = it_tag->second.first;
                    unit = it_tag->second.second;
                }

                std::string val_str = "";
                if (it.value().is_string()) {
                    val_str = to_lower(it.value().get<std::string>());
                } else if (it.value().is_number()) {
                    double dval = it.value().get<double>();
                    if (dval == static_cast<int>(dval)) {
                        val_str = std::to_string(static_cast<int>(dval));
                    } else {
                        std::ostringstream strs;
                        strs << dval;
                        val_str = strs.str();
                    }
                }

                if (is_str) {
                    if (val_str.find(pt.term) != std::string::npos) return true;
                } else {
                    bool sub_match = (val_str.find(pt.term) != std::string::npos);
                    if (sub_match) return true;

                    std::optional<double> parsed_term_unit_stripped = std::nullopt;
                    bool term_matches_unit = false;
                    if (!unit.empty()) {
                        auto it_unit = pt.unit_matches.find(unit);
                        if (it_unit != pt.unit_matches.end()) {
                            parsed_term_unit_stripped = it_unit->second.first;
                            term_matches_unit = it_unit->second.second;
                        }
                    }

                    if (term_matches_unit) return true;

                    if (pt.parsed_value.has_value() || parsed_term_unit_stripped.has_value()) {
                        auto parsed_val = parse_special_value(val_str);
                        if (parsed_val.has_value()) {
                            if (pt.parsed_value.has_value() && parsed_val.value() == pt.parsed_value.value()) {
                                return true;
                            }
                            if (parsed_term_unit_stripped.has_value() && parsed_val.value() == parsed_term_unit_stripped.value()) {
                                return true;
                            }
                        }
                    }
                }
            }
        }
        return false;
    };

    for (const auto& pt : query_terms) {
        if (!term_matches(pt)) return false;
    }
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
    if (g_cached_meta.has_value()) {
        return g_cached_meta.value();
    }
    if (!fs::exists(META_FILE)) {
        g_cached_meta = json::array();
        return g_cached_meta.value();
    }
    std::ifstream f(META_FILE);
    try {
        g_cached_meta = json::parse(f);
        return g_cached_meta.value();
    } catch (...) {
        g_cached_meta = json::array();
        return g_cached_meta.value();
    }
}

void save_meta(const json& m) {
    std::lock_guard<std::mutex> lk(g_mutex);
    g_cached_meta = m;
    std::ofstream f(META_FILE);
    f << m.dump(2);
}

// ─── Inventario & Backup ──────────────────────────────────────────────────────
json load_inv(const std::string& id) {
    std::lock_guard<std::mutex> lk(g_mutex);
    auto it = g_cached_inventories.find(id);
    if (it != g_cached_inventories.end()) {
        return it->second;
    }
    const auto p = inv_path(id);
    if (!fs::exists(p)) {
        json empty = {
            {"components", json::array()},
            {"settings", {{"drawerRows",4}, {"drawerColumns",6}, {"availableTags",json::array()}, {"tagTree",json::object()}, {"specialTags",json::array()}}}
        };
        g_cached_inventories[id] = empty;
        return empty;
    }
    std::ifstream f(p);
    try {
        json parsed = json::parse(f);
        g_cached_inventories[id] = parsed;
        return parsed;
    } catch (...) {
        json fallback = {{"components",json::array()},{"settings",json::object()}};
        g_cached_inventories[id] = fallback;
        return fallback;
    }
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
    g_cached_inventories[id] = db;
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
        
        {
            std::lock_guard<std::mutex> lk(g_mutex);
            g_cached_inventories.erase(id);
        }
        
        return json_ok({{"deleted", id}});
    });

    // ── Ricerca Globale ──
    CROW_ROUTE(app, "/api/search").methods("GET"_method)
    ([](const crow::request& req) {
        std::string q = req.url_params.get("q") ? req.url_params.get("q") : "";
        
        json results = json::array();
        std::string trimmed_query = trim(q);
        if (trimmed_query.empty()) return json_ok(results);

        auto to_lower = [](std::string s) {
            std::transform(s.begin(), s.end(), s.begin(), [](unsigned char c){ return std::tolower(c); });
            return s;
        };

        std::string query_lower = to_lower(trimmed_query);
        std::vector<std::string> raw_terms;
        std::stringstream ss(query_lower);
        std::string temp;
        while (ss >> temp) {
            raw_terms.push_back(temp);
        }

        if (raw_terms.empty()) return json_ok(results);

        // Pre-parse the query terms
        std::vector<ParsedQueryTerm> query_terms;
        for (const auto& term : raw_terms) {
            ParsedQueryTerm pt;
            pt.term = term;
            pt.parsed_value = parse_special_value(term);
            query_terms.push_back(pt);
        }

        auto meta = load_meta();
        for (const auto& inv : meta) {
            std::string inv_id = inv.value("id", "");
            std::string inv_name = inv.value("name", "");
            if (inv_id.empty()) continue;
            
            auto db = load_inv(inv_id);
            if (!db.contains("components") || !db["components"].is_array()) continue;
            
            json settings = db.value("settings", json::object());

            // Pre-process settings["specialTags"]
            std::unordered_map<std::string, std::pair<bool, std::string>> special_tags_map;
            if (settings.contains("specialTags") && settings["specialTags"].is_array()) {
                for (const auto& st : settings["specialTags"]) {
                    if (st.contains("name") && st["name"].is_string()) {
                        std::string name = st["name"].get<std::string>();
                        bool is_str = st.value("isString", false);
                        std::string unit = to_lower(st.value("unit", ""));
                        special_tags_map[name] = {is_str, unit};
                    }
                }
            }

            // Populate unit matches for each query term based on active units
            auto current_query_terms = query_terms;
            for (auto& pt : current_query_terms) {
                for (const auto& pair : special_tags_map) {
                    std::string unit = pair.second.second;
                    if (unit.empty()) continue;
                    if (pt.unit_matches.count(unit)) continue;
                    
                    std::optional<double> parsed_term_unit_stripped;
                    bool term_matches_unit = false;
                    if (pt.term.size() >= unit.size() && pt.term.compare(pt.term.size() - unit.size(), unit.size(), unit) == 0) {
                        std::string stripped = pt.term.substr(0, pt.term.size() - unit.size());
                        parsed_term_unit_stripped = parse_special_value(stripped);
                    }
                    if (unit.find(pt.term) != std::string::npos) {
                        term_matches_unit = true;
                    }
                    pt.unit_matches[unit] = {parsed_term_unit_stripped, term_matches_unit};
                }
            }

            for (const auto& comp : db["components"]) {
                if (matches_query(comp, current_query_terms, special_tags_map)) {
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

    CROW_ROUTE(app, "/api/inventories/<string>/components/<string>/move").methods("POST"_method)
    ([](const crow::request& req, const std::string& source_inv, const std::string& id) {
        if (!valid_id(source_inv)) return json_err("ID inventario non valido");
        try {
            auto body = json::parse(req.body);
            if (!body.contains("targetInventoryId")) return json_err("Destinazione mancante");
            std::string target_inv = body["targetInventoryId"].get<std::string>();
            if (!valid_id(target_inv)) return json_err("ID destinazione non valido");
            if (source_inv == target_inv) return json_err("Sorgente e destinazione uguali");

            auto source_db = load_inv(source_inv);
            auto target_db = load_inv(target_inv);

            auto& source_comps = source_db["components"];
            auto comp_it = std::find_if(source_comps.begin(), source_comps.end(), [&](const json& c) {
                return c.value("id", "") == id;
            });

            if (comp_it == source_comps.end()) {
                return json_err("Componente non trovato", 404);
            }

            json comp = *comp_it;

            // Sposta i file degli allegati fisici sul server
            std::string source_attach_dir = DATA_DIR + "/attachments/" + source_inv;
            std::string target_attach_dir = DATA_DIR + "/attachments/" + target_inv;

            auto move_file = [&](const std::string& filename) {
                if (filename.empty()) return;
                if (filename.find("..") != std::string::npos || filename.find('/') != std::string::npos) return;

                fs::path source_path = fs::path(source_attach_dir) / filename;
                fs::path target_path = fs::path(target_attach_dir) / filename;

                if (fs::exists(source_path)) {
                    fs::create_directories(target_attach_dir);
                    try {
                        fs::rename(source_path, target_path);
                    } catch (...) {
                        try {
                            fs::copy(source_path, target_path);
                            fs::remove(source_path);
                        } catch (...) {}
                    }
                }
            };

            if (comp.contains("images") && comp["images"].is_array()) {
                for (const auto& img_val : comp["images"]) {
                    if (img_val.is_string()) {
                        std::string img_path = img_val.get<std::string>();
                        if (img_path.find("http://") != 0 && img_path.find("https://") != 0 && img_path.find('/') == std::string::npos) {
                            move_file(img_path);
                        }
                    }
                }
            }

            if (comp.contains("attachments") && comp["attachments"].is_array()) {
                for (const auto& att_val : comp["attachments"]) {
                    if (att_val.is_object() && att_val.contains("path") && att_val.contains("isLink")) {
                        bool is_link = att_val.value("isLink", false);
                        std::string path = att_val.value("path", "");
                        if (!is_link && path.find('/') == std::string::npos) {
                            move_file(path);
                        }
                    }
                }
            }

            // Rimuovi da sorgente e aggiungi a destinazione
            source_comps.erase(comp_it);
            target_db["components"].push_back(comp);

            // Salva entrambi
            auto ts_source = save_inv(source_inv, source_db);
            save_inv(target_inv, target_db);

            return json_ok_ts({{"moved", true}}, ts_source);
        } catch (const std::exception& e) { return json_err(e.what()); }
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