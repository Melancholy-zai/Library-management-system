<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ page import="java.sql.*" %>
<%@ page import="com.bookborrow.util.DBUtil" %>
<!DOCTYPE html>
<html lang="zh-CN">
<head>
    <meta charset="UTF-8">
    <title>图书浏览</title>
    <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/css/bootstrap.min.css">
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.0/css/all.min.css">
    <style>
        body { background: linear-gradient(to bottom, #f8f9fa, #e9ecef); min-height: 100vh; }
        .book-card { border-radius: 15px; overflow: hidden; box-shadow: 0 4px 15px rgba(0,0,0,0.1); transition: transform 0.3s, box-shadow 0.3s; height: 500px; display: flex; flex-direction: column; }
        .book-card:hover { transform: translateY(-10px); box-shadow: 0 10px 25px rgba(0,0,0,0.2); }
        .book-img { height: 280px; object-fit: cover; width: 100%; }
        .badge-hot { background: #ffc107; color: #343a40; font-weight: bold; border-radius: 20px; padding: 0.3rem 0.8rem; }
        .no-books { text-align: center; color: #6c757d; font-style: italic; }
        .error-message { color: #dc3545; text-align: center; padding: 20px; }
        .success-message { color: #28a745; text-align: center; padding: 20px; }
        .card-body { flex-grow: 1; display: flex; flex-direction: column; padding: 1rem; }
        .card-title { margin-bottom: 0.5rem; font-size: 1.2rem; }
        .card-text { margin-bottom: 1rem; font-size: 0.9rem; }
        .btn-primary { margin-top: auto; }
        .borrow-disabled { background-color: #adb5bd !important; border: none; }
    </style>
</head>
<body>

<!-- 导航栏 -->
<nav class="navbar navbar-expand-lg navbar-light bg-light">
    <div class="container">
        <a class="navbar-brand" href="#">图书借阅平台</a>
        <button class="navbar-toggler" type="button" data-bs-toggle="collapse" data-bs-target="#navbarNav">
            <span class="navbar-toggler-icon"></span>
        </button>
        <div class="collapse navbar-collapse" id="navbarNav">
            <ul class="navbar-nav ms-auto">
                <li class="nav-item"><a class="nav-link" href="dashboard.jsp">个人中心</a></li>
                <li class="nav-item"><a class="nav-link active" href="book_list.jsp">图书浏览</a></li>
                <li class="nav-item"><a class="nav-link" href="borrow_list.jsp">借阅记录</a></li>
                <li class="nav-item"><a class="nav-link" href="../logoutServlet">退出</a></li>
            </ul>
        </div>
    </div>
</nav>

<div class="container my-5">
    <h2 class="text-center mb-4">图书浏览与借阅</h2>

    <%
        Integer userId = (Integer) session.getAttribute("userId");
        if (userId == null) {
            response.sendRedirect("../login.jsp");
            return;
        }

        int borrowLimit = 0;
        int currentBorrowed = 0;

        try (Connection conn = DBUtil.getConnection()) {
            // 查询借阅上限
            try (PreparedStatement ps1 = conn.prepareStatement("SELECT borrow_limit FROM rjgc_users WHERE id=?")) {
                ps1.setInt(1, userId);
                ResultSet r1 = ps1.executeQuery();
                if (r1.next()) borrowLimit = r1.getInt(1);
            }

            // 查询当前借阅数
            try (PreparedStatement ps2 = conn.prepareStatement(
                    "SELECT COUNT(*) FROM rjgc_borrow_records WHERE user_id=? AND status IN ('借阅中','逾期')")) {
                ps2.setInt(1, userId);
                ResultSet r2 = ps2.executeQuery();
                if (r2.next()) currentBorrowed = r2.getInt(1);
            }
        } catch (Exception e) {
            e.printStackTrace();
        }
        int remaining = borrowLimit - currentBorrowed;
    %>

    <!-- 借阅状态提示 -->
    <div class="alert alert-info text-center">
        当前借阅 <strong><%= currentBorrowed %></strong> 本 /
        上限 <strong><%= borrowLimit %></strong> 本，
        还可借 <strong><%= Math.max(0, remaining) %></strong> 本
    </div>

    <!-- 返回所有书籍按钮 -->
    <a href="book_list.jsp" class="btn btn-secondary mb-4">返回所有书籍</a>

    <!-- 搜索框 -->
    <form class="mb-4" action="book_list.jsp" method="get">
        <div class="input-group input-group-lg">
            <input type="text" class="form-control rounded-pill me-2" name="search"
                   placeholder="搜索 ISBN 或书名..."
                   value="<%= request.getParameter("search") != null ? request.getParameter("search") : "" %>">
            <button class="btn btn-primary rounded-pill" type="submit"><i class="fas fa-search me-2"></i>搜索</button>
        </div>
    </form>

    <!-- 显示提示信息 -->
    <%
        String error = request.getParameter("error");
        String msg = request.getParameter("msg");
        if (error != null) {
    %>
    <div class="alert alert-danger text-center"><%= error %></div>
    <%
    } else if (msg != null) {
    %>
    <div class="alert alert-success text-center"><%= msg %></div>
    <%
        }
    %>

    <!-- 显示图书列表 -->
    <div class="row g-4">
        <%
            boolean hasBooks = false;
            String errorMessage = null;
            String searchQuery = request.getParameter("search"); // 获取搜索参数

            try (Connection conn = DBUtil.getConnection()) {
                String sql;
                PreparedStatement pstmt;

                if (searchQuery != null && !searchQuery.trim().isEmpty()) {
                    // 搜索模式：按书名或ISBN模糊搜索
                    sql = "SELECT * FROM rjgc_books WHERE available_copies > 0 AND (title LIKE ? OR isbn LIKE ?)";
                    pstmt = conn.prepareStatement(sql);
                    pstmt.setString(1, "%" + searchQuery + "%");
                    pstmt.setString(2, "%" + searchQuery + "%");
                } else {
                    // 正常模式：显示所有可借阅图书
                    sql = "SELECT * FROM rjgc_books WHERE available_copies > 0";
                    pstmt = conn.prepareStatement(sql);
                }

                ResultSet rs = pstmt.executeQuery();
                while (rs.next()) {
                    hasBooks = true;
                    String cover = rs.getString("cover_url");  // 确保查询了 cover_url 字段
                    if (cover == null || cover.isEmpty()) cover = "../images/default-book.jpg"; // 默认封面
                    boolean isHot = rs.getBoolean("is_hot");
        %>
        <div class="col-md-3 col-sm-6">
            <div class="card book-card">
                <img src="<%= cover %>" class="card-img-top book-img" alt="<%= rs.getString("title") != null ? rs.getString("title") : "未知书名" %>">
                <div class="card-body text-center">
                    <h5 class="card-title"><%= rs.getString("title") != null ? rs.getString("title") : "未知书名" %></h5>
                    <p class="card-text text-muted">
                        作者: <%= rs.getString("author") != null ? rs.getString("author") : "未知作者" %><br>
                        ISBN: <%= rs.getString("isbn") != null ? rs.getString("isbn") : "未知ISBN" %>
                    </p>
                    <% if (isHot) { %><span class="badge badge-hot mb-2">热门推荐</span><% } %>
                    <form action="../borrowServlet" method="post">
                        <input type="hidden" name="bookId" value="<%= rs.getInt("id") %>">
                        <% if (remaining > 0) { %>
                        <button type="submit" class="btn btn-primary w-100">借阅</button>
                        <% } else { %>
                        <button type="button" class="btn btn-secondary w-100 borrow-disabled" disabled>
                            已达借阅上限
                        </button>
                        <% } %>
                    </form>
                </div>
            </div>
        </div>
        <%
                }
            } catch (Exception e) {
                errorMessage = "查询图书失败: " + e.getMessage();
                e.printStackTrace();
            }

            if (!hasBooks && errorMessage == null) {
                if (searchQuery != null && !searchQuery.trim().isEmpty()) {
                    // 搜索结果为空
        %>
        <div class="col-12">
            <p class='no-books mt-5'>没有找到包含 "<%= searchQuery %>" 的图书，请尝试其他关键词。</p>
        </div>
        <%
        } else {
            // 没有可用图书
        %>
        <div class="col-12">
            <p class='no-books mt-5'>暂无可用图书，请联系管理员添加！</p>
        </div>
        <%
            }
        } else if (errorMessage != null) {
        %>
        <div class="col-12">
            <div class='alert alert-danger text-center'><%= errorMessage %></div>
        </div>
        <%
            }
        %>
    </div>
</div>

<script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/js/bootstrap.bundle.min.js"></script>
</body>
</html>