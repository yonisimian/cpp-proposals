#include <format>
#include <print>
#include <tuple>
#include <utility>

struct Point { int x, y; };

template <>
struct std::formatter<Point> {
    constexpr auto parse(std::format_parse_context& ctx) const { return ctx.begin(); }
    auto format(const Point& p, std::format_context& ctx) const {
        return std::format_to(ctx.out(), "({}, {})", p.x, p.y);
    }
};

// ── Current alternative 1: std::tie ──────────────────────────────────────────
template <typename... Ts>
void assign_with_tie(std::tuple<Ts...> t, Ts&... targets) {
    std::tie(targets...) = std::move(t);
}

// ── Current alternative 2: index sequence ────────────────────────────────────
template <typename... Ts>
void assign_with_index_seq(std::tuple<Ts...> t, Ts&... targets) {
    [&]<std::size_t... Is>(std::index_sequence<Is...>) {
        // Pack expansion (not fold): Is and targets expand in parallel
        int dummy[] = { (targets = std::get<Is>(std::move(t)), 0)... };
        (void)dummy;
    }(std::index_sequence_for<Ts...>{});
}

// ── P3817 (proposed — not yet implemented in compilers) ──────────────────────
// template <typename... Ts>
// void assign_p3817(std::tuple<Ts...> t, Ts&... targets) {
//     auto [using ...targets] = std::move(t);
// }

template <typename... Ts>
void print_pack(const char* label, const Ts&... targets) {
    std::print("{}:\n", label);
    std::size_t i = 0;
    ((std::print("  [{}] = {}\n", i++, targets)), ...);
}

int main() {
    Point p{}, q{}, r{};

    assign_with_tie(
        std::make_tuple(Point{1, 2}, Point{3, 4}, Point{5, 6}),
        p, q, r);
    print_pack("std::tie", p, q, r);

    assign_with_index_seq(
        std::make_tuple(Point{7, 8}, Point{9, 10}, Point{11, 12}),
        p, q, r);
    print_pack("index sequence", p, q, r);
}
