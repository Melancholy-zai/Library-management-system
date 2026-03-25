<!-- user/notifications.jsp -->
<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ page import="java.sql.*" %>
<%@ page import="com.bookborrow.util.DBUtil" %>
<!DOCTYPE html>
<html lang="zh-CN">
<head>
    <style>
    .navbar-brand {
        font-weight: bold;
        font-size: 1.3rem;
    }
    .nav-link {
        font-size: 0.95rem;
        transition: color 0.3s;
    }
    .nav-link:hover {
        color: #007bff !important;
    }
    .navbar-toggler-icon {
        background-image: url("data:image/svg+xml;charset=utf-8,%3Csvg xmlns='http://www.w3.org/2000/svg' width='24' height='24' viewBox='0 0 24 24'%3E%3Cpath fill='none' stroke='%23000' stroke-width='2' d='M4 6h16M4 12h16M4 18h16'/%3E%3C/svg%3E");
    }
    </style>
    <style>
    .card {
        border-radius: 12px;
        box-shadow: 0 4px 12px rgba(0,0,0,0.1);
        transition: all 0.3s ease;
    }
    .card:hover {
        transform: translateY(-4px);
        box-shadow: 0 8px 20px rgba(0,0,0,0.15);
    }
    .btn-primary {
        border-radius: 50px;
        padding: 0.5rem 1.5rem;
        font-weight: 500;
    }
    .btn-secondary {
        border-radius: 50px;
        padding: 0.5rem 1.5rem;
    }
    </style>

    <style>
    .notification-title {
        font-size: 1.1rem;
        margin-bottom: 0.5rem;
        font-weight: 500;
    }
    .notification-content {
        color: #6c757d;
        margin-bottom: 0.5rem;
    }
    .notification-time {
        font-size: 0.9rem;
        color: #6c757d;
    }
    .status-read {
        color: #6c757d;
    }
    .status-unread {
        font-weight: bold;
        color: #007bff;
    }
</style>


    <meta charset="UTF-8">
    <title>通知中心</title>
    <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/css/bootstrap.min.css">
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.0/css/all.min.css">
    <style>
        .table th, .table td { vertical-align: middle; }
        .status-read { color: #6c757d; }
        .status-unread { font-weight: bold; }
        .notification-title {
            font-size: 1.1rem;
            margin-bottom: 0.5rem;
        }
        .notification-content {
            color: #6c757d;
            margin-bottom: 0.5rem;
        }
        .notification-time {
            font-size: 0.9rem;
            color: #6c757d;
        }
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
                <li class="nav-item"><a class="nav-link" href="book_list.jsp">图书浏览</a></li>
                <li class="nav-item"><a class="nav-link" href="borrow_list.jsp">借阅记录</a></li>
                <li class="nav-item"><a class="nav-link" href="../logoutServlet">退出</a></li>
            </ul>
        </div>
    </div>
</nav>

<div class="container my-5">
    <h2 class="text-center mb-4">通知中心</h2>

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

    <div class="card">
        <div class="card-body">
            <table class="table table-hover">
                <thead class="table-light">
                    <tr>
                        <th>标题</th>
                        <th>内容</th>
                        <th>时间</th>
                        <th>状态</th>
                    </tr>
                </thead>
                <tbody>
                    <%
                        Integer userId = (Integer) session.getAttribute("userId");
                        try (Connection conn = DBUtil.getConnection()) {
                            String sql = "SELECT * FROM rjgc_notifications WHERE user_id = ? ORDER BY sent_at DESC";
                            PreparedStatement pstmt = conn.prepareStatement(sql);
                            pstmt.setInt(1, userId);
                            ResultSet rs = pstmt.executeQuery();

                            while (rs.next()) {
                                boolean isRead = rs.getBoolean("is_read");
                                String statusClass = isRead ? "status-read" : "status-unread";
                    %>
                    <tr>
                        <td>
                            <div class="notification-title"><%= rs.getString("title") %></div>
                            <div class="notification-content"><%= rs.getString("content") %></div>
                        </td>
                        <td><%= rs.getTimestamp("sent_at") %></td>
                        <td><span class="<%= statusClass %>"><%= isRead ? "已读" : "未读" %></span></td>
                    </tr>
                    <%
                            }
                        } catch (Exception e) {
                            e.printStackTrace();
                    %>
                    <tr>
                        <td colspan="4" class="text-center">查询通知失败</td>
                    </tr>
                    <%
                        }
                    %>
                </tbody>
            </table>
        </div>
    </div>
</div>

<script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/js/bootstrap.bundle.min.js"></script>
</body>
</html>
