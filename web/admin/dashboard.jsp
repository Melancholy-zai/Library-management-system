<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ page import="java.sql.*" %>
<%@ page import="com.bookborrow.util.DBUtil" %>

<%
    int totalBooks = 0;
    int totalUsers = 0;
    int pendingReview = 0;
    int overdueCount = 0;

    Connection conn = null;
    try {
        conn = DBUtil.getConnection();

        // 1) 总图书
        try (PreparedStatement ps = conn.prepareStatement("SELECT COUNT(*) FROM rjgc_books");
             ResultSet rs = ps.executeQuery()) {
            if (rs.next()) totalBooks = rs.getInt(1);
        }

        // 2) 注册用户（按你的需求：如果你想排除管理员，改成 WHERE user_type='user'）
        try (PreparedStatement ps = conn.prepareStatement("SELECT COUNT(*) FROM rjgc_users");
             ResultSet rs = ps.executeQuery()) {
            if (rs.next()) totalUsers = rs.getInt(1);
        }

        // 3) 待审核（borrow_requests 的 PENDING + borrow_records 的 待审核）
        int pendingReq = 0;
        int pendingRec = 0;

        try (PreparedStatement ps = conn.prepareStatement(
                "SELECT COUNT(*) FROM rjgc_borrow_requests WHERE status='PENDING'");
             ResultSet rs = ps.executeQuery()) {
            if (rs.next()) pendingReq = rs.getInt(1);
        }

        try (PreparedStatement ps = conn.prepareStatement(
                "SELECT COUNT(*) FROM rjgc_borrow_records WHERE status='待审核'");
             ResultSet rs = ps.executeQuery()) {
            if (rs.next()) pendingRec = rs.getInt(1);
        }

        pendingReview = pendingReq + pendingRec;

        // 4) 逾期（状态为逾期，或已超过 due_date 且未归还）
        try (PreparedStatement ps = conn.prepareStatement(
                "SELECT COUNT(*) " +
                        "FROM rjgc_borrow_records " +
                        "WHERE status='逾期' " +
                        "   OR (return_date IS NULL AND due_date IS NOT NULL AND due_date < CURDATE())");
             ResultSet rs = ps.executeQuery()) {
            if (rs.next()) overdueCount = rs.getInt(1);
        }

    } catch (Exception e) {
        // 出错时避免页面直接炸掉
        e.printStackTrace();
    } finally {
        try { if (conn != null) conn.close(); } catch (Exception ignored) {}
    }
%>

<!DOCTYPE html>
<html lang="zh-CN">
<head>
    <meta charset="UTF-8">
    <title>管理员面板</title>

    <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/css/bootstrap.min.css">
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.0/css/all.min.css">
    <script src="https://cdn.jsdelivr.net/npm/chart.js"></script>

    <style>
        :root{
            --glass-bg: rgba(255,255,255,.72);
            --glass-border: rgba(255,255,255,.35);
            --shadow: 0 12px 35px rgba(16,24,40,.14);
            --shadow-soft: 0 8px 22px rgba(16,24,40,.10);
        }

        /* 全局背景：本地图片 + 渐变遮罩 */
        body {
            min-height: 100vh;
            background:
                    linear-gradient(180deg, rgba(10,20,40,.70) 0%, rgba(10,20,40,.45) 40%, rgba(246,248,252,1) 100%),
                    url("<%= request.getContextPath() %>/images/dashboard-bg.jpg") center/cover no-repeat fixed;
        }

        .page-wrap{ padding-bottom: 60px; }

        .hero {
            margin-top: 18px;
            border-radius: 22px;
            overflow: hidden;
            position: relative;
            box-shadow: var(--shadow);
            border: 1px solid rgba(255,255,255,.18);
        }
        .hero::before{
            content:"";
            position:absolute;
            inset:0;
            background:
                    radial-gradient(1000px 400px at 20% 20%, rgba(99,102,241,.55), transparent 60%),
                    radial-gradient(900px 420px at 85% 35%, rgba(14,165,233,.45), transparent 60%),
                    linear-gradient(135deg, rgba(15,23,42,.65), rgba(15,23,42,.25));
        }
        .hero-inner{
            position: relative;
            padding: 54px 28px;
            backdrop-filter: blur(8px);
        }
        .hero h1{ color: #fff; font-weight: 800; letter-spacing: .5px; }
        .hero p{ color: rgba(255,255,255,.82); margin-bottom: 0; }
        .hero-badges{
            margin-top: 16px;
            display: flex;
            flex-wrap: wrap;
            gap: 10px;
        }
        .pill{
            display:inline-flex;
            align-items:center;
            gap:8px;
            padding: 8px 12px;
            border-radius: 999px;
            background: rgba(255,255,255,.14);
            border: 1px solid rgba(255,255,255,.22);
            color: rgba(255,255,255,.9);
            font-size: 13px;
        }

        .stat-card{
            border-radius: 18px;
            border: 1px solid var(--glass-border);
            background: var(--glass-bg);
            backdrop-filter: blur(10px);
            box-shadow: var(--shadow-soft);
            transition: transform .18s ease, box-shadow .18s ease;
            overflow: hidden;
            position: relative;
        }
        .stat-card:hover{
            transform: translateY(-3px);
            box-shadow: var(--shadow);
        }
        .stat-card .icon-wrap{
            width: 52px;
            height: 52px;
            border-radius: 16px;
            display: grid;
            place-items: center;
            color: #fff;
            box-shadow: 0 10px 20px rgba(0,0,0,.15);
        }
        .stat-card h3{
            font-size: 14px;
            color: #334155;
            margin: 0;
            font-weight: 700;
        }
        .stat-card h2{
            margin: 8px 0 0 0;
            font-size: 34px;
            font-weight: 900;
            color: #0f172a;
            letter-spacing: .5px;
        }

        .grad-primary{ background: linear-gradient(135deg, #2563eb, #7c3aed); }
        .grad-success{ background: linear-gradient(135deg, #16a34a, #22c55e); }
        .grad-warning{ background: linear-gradient(135deg, #f59e0b, #f97316); }
        .grad-danger { background: linear-gradient(135deg, #ef4444, #f43f5e); }

        .cardx{
            border-radius: 20px;
            border: 1px solid var(--glass-border);
            background: rgba(255,255,255,.78);
            backdrop-filter: blur(10px);
            box-shadow: var(--shadow);
            overflow: hidden;
        }
        .cardx .card-header{
            background: rgba(255,255,255,.55);
            border-bottom: 1px solid rgba(15,23,42,.08);
            padding: 16px 18px;
        }
        .cardx .card-header h5{
            margin: 0;
            font-weight: 800;
            color: #0f172a;
        }
        .cardx .card-body{ padding: 18px; }

        .chart-wrap{ position: relative; height: 320px; }

        @media (max-width: 768px) {
            .hero-inner{ padding: 42px 18px; }
            .chart-wrap{ height: 260px; }
        }
    </style>
</head>
<body>

<jsp:include page="_navbar.jsp"/>

<div class="container page-wrap">

    <div class="hero">
        <div class="hero-inner">
            <h1 class="mb-2">管理员仪表盘</h1>
            <p>高效管理图书馆 · 统计趋势一目了然</p>

            <div class="hero-badges">
                <span class="pill"><i class="fa-solid fa-shield-halved"></i> 管理员权限</span>
                <span class="pill"><i class="fa-regular fa-chart-bar"></i> 数据统计</span>
                <span class="pill"><i class="fa-regular fa-clock"></i> 实时更新</span>
            </div>
        </div>
    </div>

    <!-- 统计卡片（已改成动态） -->
    <div class="row g-4 mt-2">
        <div class="col-lg-3 col-md-6">
            <div class="stat-card p-4">
                <div class="d-flex align-items-center justify-content-between">
                    <div>
                        <h3>总图书</h3>
                        <h2><%= totalBooks %></h2>
                    </div>
                    <div class="icon-wrap grad-primary">
                        <i class="fa-solid fa-book fs-4"></i>
                    </div>
                </div>
                <div class="mt-2 small text-muted">库存总量</div>
            </div>
        </div>

        <div class="col-lg-3 col-md-6">
            <div class="stat-card p-4">
                <div class="d-flex align-items-center justify-content-between">
                    <div>
                        <h3>注册用户</h3>
                        <h2><%= totalUsers %></h2>
                    </div>
                    <div class="icon-wrap grad-success">
                        <i class="fa-solid fa-users fs-4"></i>
                    </div>
                </div>
                <div class="mt-2 small text-muted">累计注册</div>
            </div>
        </div>

        <div class="col-lg-3 col-md-6">
            <div class="stat-card p-4">
                <div class="d-flex align-items-center justify-content-between">
                    <div>
                        <h3>待审核</h3>
                        <h2><%= pendingReview %></h2>
                    </div>
                    <div class="icon-wrap grad-warning">
                        <i class="fa-solid fa-hourglass-half fs-4"></i>
                    </div>
                </div>
                <div class="mt-2 small text-muted">待处理事项</div>
            </div>
        </div>

        <div class="col-lg-3 col-md-6">
            <div class="stat-card p-4">
                <div class="d-flex align-items-center justify-content-between">
                    <div>
                        <h3>逾期</h3>
                        <h2><%= overdueCount %></h2>
                    </div>
                    <div class="icon-wrap grad-danger">
                        <i class="fa-solid fa-triangle-exclamation fs-4"></i>
                    </div>
                </div>
                <div class="mt-2 small text-muted">需尽快处理</div>
            </div>
        </div>
    </div>

    <!-- 图表卡片（你原来保持不动：仍是模拟数据） -->
    <div class="cardx mt-4">
        <div class="card-header d-flex align-items-center justify-content-between">
            <h5><i class="fa-solid fa-chart-line me-2"></i>近 6 个月借阅趋势</h5>
            <span class="text-muted small">Borrow Trend</span>
        </div>
        <div class="card-body">
            <div class="chart-wrap">
                <canvas id="borrowTrendChart"></canvas>
            </div>
        </div>
    </div>

</div>

<script>
    const months = ['2025-07', '2025-08', '2025-09', '2025-10', '2025-11', '2025-12'];
    const borrowCounts = [12, 25, 18, 30, 40, 50];

    Chart.defaults.font.family = 'system-ui,-apple-system,Segoe UI,Roboto,Helvetica,Arial,"PingFang SC","Microsoft Yahei"';

    new Chart(document.getElementById('borrowTrendChart'), {
        type: 'line',
        data: {
            labels: months,
            datasets: [{
                label: '借阅量',
                data: borrowCounts,
                borderColor: '#0d6efd',
                backgroundColor: 'rgba(13,110,253,.10)',
                pointRadius: 3,
                pointHoverRadius: 5,
                tension: 0.35,
                fill: true
            }]
        },
        options: {
            responsive: true,
            maintainAspectRatio: false,
            plugins: {
                legend: { display: true },
                tooltip: { intersect: false, mode: 'index' }
            },
            scales: {
                x: { grid: { display: false } },
                y: { beginAtZero: true, ticks: { precision: 0 } }
            }
        }
    });
</script>

<script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/js/bootstrap.bundle.min.js"></script>
</body>
</html>
