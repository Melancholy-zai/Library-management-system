<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ page import="java.sql.*" %>
<%@ page import="java.util.*" %>
<%@ page import="java.text.SimpleDateFormat" %>
<%@ page import="com.bookborrow.util.DBUtil" %>

<%!
    // 把 Java List<String> 安全输出为 JS 数组字符串：["a","b","c"]
    private String toJsStringArray(List<String> list) {
        StringBuilder sb = new StringBuilder();
        sb.append("[");
        for (int i = 0; i < list.size(); i++) {
            String s = list.get(i);
            if (s == null) s = "";
            // 简单转义：\ 和 " 和换行
            s = s.replace("\\", "\\\\").replace("\"", "\\\"").replace("\n", "\\n").replace("\r", "");
            sb.append("\"").append(s).append("\"");
            if (i < list.size() - 1) sb.append(",");
        }
        sb.append("]");
        return sb.toString();
    }

    // Java List<Integer> 输出为 JS 数组：[1,2,3]
    private String toJsNumberArray(List<Integer> list) {
        return list.toString();
    }
%>

<!DOCTYPE html>
<html lang="zh-CN">
<head>
    <meta charset="UTF-8">
    <title>数据统计</title>

    <!-- Bootstrap -->
    <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/css/bootstrap.min.css">
    <!-- FontAwesome（你标题里用了 fa-solid，不引入会没图标） -->
    <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/@fortawesome/fontawesome-free@6.5.0/css/all.min.css">
    <!-- Chart.js -->
    <script src="https://cdn.jsdelivr.net/npm/chart.js"></script>

    <style>
        body {
            background: radial-gradient(1200px 600px at 20% 0%, #ffffff 0%, #f6f8fb 35%, #eef2f7 100%);
            min-height: 100vh;
        }

        .page-title {
            display: flex;
            align-items: center;
            gap: 10px;
        }

        .cardx {
            border: 0;
            border-radius: 18px;
            box-shadow: 0 10px 30px rgba(16, 24, 40, .08);
            background: rgba(255,255,255,.92);
            backdrop-filter: blur(6px);
        }

        .cardx .card-head {
            display: flex;
            align-items: center;
            justify-content: space-between;
            gap: 12px;
            margin-bottom: 10px;
        }

        .muted {
            color: #6b7280;
            font-size: .9rem;
        }

        /* 统一图表区域高度，让两张图对齐整齐 */
        .chart-wrap {
            position: relative;
            height: 260px;
        }

        .pill {
            border-radius: 999px;
            padding: 6px 10px;
            font-size: 12px;
            background: #f1f5f9;
            color: #0f172a;
            border: 1px solid #e2e8f0;
            white-space: nowrap;
        }

        .table thead th {
            color: #475569;
            font-weight: 600;
            border-bottom: 1px solid #e5e7eb;
        }

        .badge-soft {
            background: #111827;
            color: #fff;
            border-radius: 999px;
            padding: 6px 10px;
            font-weight: 600;
        }
    </style>
</head>
<body>

<jsp:include page="_navbar.jsp"/>

<div class="container my-4">
    <div class="d-flex align-items-end justify-content-between flex-wrap gap-2 mb-3">
        <div class="page-title">
            <i class="fa-solid fa-chart-line fs-4"></i>
            <div>
                <div class="h4 mb-0">数据统计</div>
                <div class="muted">借阅趋势 · 分类热度 · 热门图书</div>
            </div>
        </div>
        <div class="pill">
            <i class="fa-regular fa-clock me-1"></i>
            数据来源：借阅记录（rjgc_borrow_records）
        </div>
    </div>

    <%
        // 1) 近6个月借阅量（补齐没有数据的月份，避免图表只有一个点/不连续）
        List<String> months = new ArrayList<>();
        List<Integer> monthCounts = new ArrayList<>();

        // 2) 分类借阅量 Top
        List<String> cats = new ArrayList<>();
        List<Integer> catCounts = new ArrayList<>();

        // 3) Top books
        class TopBook { String title; int cnt; TopBook(String t,int c){title=t;cnt=c;} }
        List<TopBook> topBooks = new ArrayList<>();

        try (Connection conn = DBUtil.getConnection()) {

            // --- 近 6 个月月份列表（包含本月） ---
            // 先生成月份框架：yyyy-MM 共6个
            LinkedHashMap<String, Integer> monthMap = new LinkedHashMap<>();
            Calendar cal = Calendar.getInstance();
            cal.set(Calendar.DAY_OF_MONTH, 1); // 月初
            SimpleDateFormat ymFmt = new SimpleDateFormat("yyyy-MM");

            // 从 5 个月前到本月，共 6 个
            cal.add(Calendar.MONTH, -5);
            for (int i = 0; i < 6; i++) {
                monthMap.put(ymFmt.format(cal.getTime()), 0);
                cal.add(Calendar.MONTH, 1);
            }

            // 查真实数据覆盖进去
            try (PreparedStatement ps = conn.prepareStatement(
                    "SELECT DATE_FORMAT(borrow_date,'%Y-%m') ym, COUNT(*) cnt " +
                            "FROM rjgc_borrow_records " +
                            "WHERE borrow_date >= DATE_SUB(CURDATE(), INTERVAL 6 MONTH) " +
                            "GROUP BY ym ORDER BY ym"
            )) {
                ResultSet rs = ps.executeQuery();
                while (rs.next()) {
                    String ym = rs.getString("ym");
                    int cnt = rs.getInt("cnt");
                    if (monthMap.containsKey(ym)) monthMap.put(ym, cnt);
                }
            }

            for (Map.Entry<String, Integer> e : monthMap.entrySet()) {
                months.add(e.getKey());
                monthCounts.add(e.getValue());
            }

            // --- 分类借阅 Top（有数据但图表没显示，多半是 JS 数组没加引号，这里后面会修复输出） ---
            try (PreparedStatement ps = conn.prepareStatement(
                    "SELECT IFNULL(b.category,'未分类') c, COUNT(*) cnt " +
                            "FROM rjgc_borrow_records r JOIN rjgc_books b ON r.book_id=b.id " +
                            "GROUP BY c ORDER BY cnt DESC LIMIT 8"
            )) {
                ResultSet rs = ps.executeQuery();
                while (rs.next()) {
                    cats.add(rs.getString("c"));
                    catCounts.add(rs.getInt("cnt"));
                }
            }

            // --- Top 5 图书 ---
            try (PreparedStatement ps = conn.prepareStatement(
                    "SELECT b.title t, COUNT(*) cnt " +
                            "FROM rjgc_borrow_records r JOIN rjgc_books b ON r.book_id=b.id " +
                            "GROUP BY b.id, b.title ORDER BY cnt DESC LIMIT 5"
            )) {
                ResultSet rs = ps.executeQuery();
                while (rs.next()) topBooks.add(new TopBook(rs.getString("t"), rs.getInt("cnt")));
            }

        } catch (Exception e) {
    %>
    <div class="alert alert-danger cardx p-3">统计加载失败：<%= e.getMessage() %></div>
    <%
        }
    %>

    <!-- 两张图：同高同样式 -->
    <div class="row g-3 align-items-stretch">
        <div class="col-lg-6">
            <div class="card cardx p-3 h-100">
                <div class="card-head">
                    <div>
                        <div class="h5 mb-0">近 6 个月借阅量</div>
                        <div class="muted">按月份统计借阅记录数</div>
                    </div>
                    <span class="pill"><i class="fa-solid fa-chart-line me-1"></i>趋势</span>
                </div>
                <div class="chart-wrap">
                    <canvas id="mChart"></canvas>
                </div>
            </div>
        </div>

        <div class="col-lg-6">
            <div class="card cardx p-3 h-100">
                <div class="card-head">
                    <div>
                        <div class="h5 mb-0">分类借阅 Top</div>
                        <div class="muted">按分类统计借阅热度（Top 8）</div>
                    </div>
                    <span class="pill"><i class="fa-solid fa-layer-group me-1"></i>排行</span>
                </div>

                <%
                    if (cats.isEmpty()) {
                %>
                <div class="alert alert-warning mb-0">
                    暂无分类借阅数据（请确认：图书表 rjgc_books.category 是否有值，且借阅记录 rjgc_borrow_records.book_id 能关联到图书）。
                </div>
                <div class="chart-wrap mt-2">
                    <canvas id="cChart"></canvas>
                </div>
                <%
                } else {
                %>
                <div class="chart-wrap">
                    <canvas id="cChart"></canvas>
                </div>
                <%
                    }
                %>
            </div>
        </div>
    </div>

    <!-- Top5 表 -->
    <div class="card cardx p-3 mt-3">
        <div class="card-head">
            <div>
                <div class="h5 mb-0">Top 5 热门图书</div>
                <div class="muted">按借阅次数统计</div>
            </div>
            <span class="pill"><i class="fa-solid fa-fire me-1"></i>热度</span>
        </div>

        <div class="table-responsive">
            <table class="table table-hover align-middle mb-0">
                <thead>
                <tr><th style="width:80px;">#</th><th>书名</th><th style="width:140px;">借阅次数</th></tr>
                </thead>
                <tbody>
                <%
                    if (topBooks.isEmpty()) {
                %>
                <tr><td colspan="3" class="text-center text-muted py-4">暂无借阅数据</td></tr>
                <%
                } else {
                    for (int i=0;i<topBooks.size();i++) {
                        TopBook tb = topBooks.get(i);
                %>
                <tr>
                    <td class="text-muted"><%= (i+1) %></td>
                    <td class="fw-semibold"><%= tb.title %></td>
                    <td><span class="badge-soft"><%= tb.cnt %></span></td>
                </tr>
                <%
                        }
                    }
                %>
                </tbody>
            </table>
        </div>

        <%
            String suggestion = "建议：暂无足够数据生成采购建议。";
            if (!cats.isEmpty()) {
                suggestion = "建议：优先增加【" + cats.get(0) + "】类图书采购与前排陈列（当前借阅最高）。";
            }
        %>
        <div class="alert alert-info mt-3 mb-0"><%= suggestion %></div>
    </div>

</div>

<script>
    // ✅关键修复：labels 必须是 JS 字符串数组，而不是 [计算机, 文学] 这种
    const months = <%= toJsStringArray(months) %>;
    const monthCounts = <%= toJsNumberArray(monthCounts) %>;

    const cats = <%= toJsStringArray(cats) %>;
    const catCounts = <%= toJsNumberArray(catCounts) %>;

    // 全局默认：更“干净”的观感
    Chart.defaults.font.family = 'system-ui,-apple-system,Segoe UI,Roboto,Helvetica,Arial,"PingFang SC","Microsoft Yahei"';
    Chart.defaults.plugins.legend.labels.boxWidth = 10;

    // 折线图：近6个月
    new Chart(document.getElementById('mChart'), {
        type: 'line',
        data: {
            labels: months,
            datasets: [{
                label: '借阅量',
                data: monthCounts,
                tension: 0.35,
                pointRadius: 3,
                pointHoverRadius: 5,
                fill: false
            }]
        },
        options: {
            responsive: true,
            maintainAspectRatio: false,  // ✅配合 chart-wrap 固定高度，避免“不整齐”
            plugins: {
                legend: { display: true },
                tooltip: { intersect: false, mode: 'index' }
            },
            scales: {
                y: { beginAtZero: true, ticks: { precision: 0 } },
                x: { grid: { display: false } }
            }
        }
    });

    // 柱状图：分类Top
    new Chart(document.getElementById('cChart'), {
        type: 'bar',
        data: {
            labels: cats,
            datasets: [{
                label: '借阅量',
                data: catCounts,
                borderWidth: 1,
                borderRadius: 10,
                maxBarThickness: 38
            }]
        },
        options: {
            responsive: true,
            maintainAspectRatio: false,  // ✅固定高度
            plugins: {
                legend: { display: true },
                tooltip: { intersect: false, mode: 'index' }
            },
            scales: {
                y: { beginAtZero: true, ticks: { precision: 0 } },
                x: { grid: { display: false } }
            }
        }
    });
</script>

<script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/js/bootstrap.bundle.min.js"></script>
</body>
</html>
