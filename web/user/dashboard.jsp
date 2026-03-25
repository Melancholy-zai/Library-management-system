<!-- user/dashboard.jsp (修复编译错误) -->
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
        border: none;
        border-radius: 15px;
        box-shadow: 0 4px 20px rgba(0,0,0,0.1);
        transition: transform 0.3s;
    }
    .card:hover {
        transform: translateY(-10px);
    }
    .profile-img {
        width: 120px;
        height: 120px;
        object-fit: cover;
        border: 5px solid white;
        box-shadow: 0 4px 15px rgba(0,0,0,0.2);
    }
    .header {
        background-image: url('../images/header-bg.jpg');
        background-size: cover;
        color: white;
        padding: 100px 0;
        text-align: center;
    }
</style>



    <meta charset="UTF-8">
    <title>个人中心 - 线上图书借阅平台</title>
    <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/css/bootstrap.min.css">
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.0/css/all.min.css">
    <style>
        body { background: #f5f7fa; }
        .header { background-image: url('../images/header-bg.jpg'); background-size: cover; color: white; padding: 100px 0; text-align: center; }
        .card { border: none; border-radius: 15px; box-shadow: 0 4px 20px rgba(0,0,0,0.1); transition: transform 0.3s; }
        .card:hover { transform: translateY(-10px); }
        .nav-link { font-size: 1.1rem; }
        .profile-img { width: 120px; height: 120px; object-fit: cover; border: 5px solid white; box-shadow: 0 4px 15px rgba(0,0,0,0.2); }
    </style>
</head>
<body>
<div class="header">
    <h1>欢迎回来，<%= session.getAttribute("username") %>！</h1>
    <p>享受阅读的乐趣</p>
</div>

<nav class="navbar navbar-expand-lg navbar-light bg-white shadow-sm">
    <div class="container">
        <a class="navbar-brand" href="../index.jsp">图书平台</a>
        <div class="collapse navbar-collapse">
            <ul class="navbar-nav ms-auto">
                <li class="nav-item"><a class="nav-link" href="dashboard.jsp"><i class="fas fa-home me-1"></i>个人中心</a></li>
                <li class="nav-item"><a class="nav-link" href="book_list.jsp"><i class="fas fa-book me-1"></i>图书浏览</a></li>
                <li class="nav-item"><a class="nav-link" href="borrow_list.jsp"><i class="fas fa-list me-1"></i>借阅记录</a></li>
                <li class="nav-item"><a class="nav-link" href="feedback.jsp"><i class="fas fa-comment me-1"></i>反馈评价</a></li>
                <li class="nav-item"><a class="nav-link text-danger" href="../logoutServlet"><i class="fas fa-sign-out-alt me-1"></i>退出</a></li>
            </ul>
        </div>
    </div>
</nav>

<div class="container my-5">
    <div class="row">
        <div class="col-md-4">
            <div class="card text-center p-4">
                <%
                    String avatarUrl = "../images/profile-default.jpg";
                    try (Connection conn = DBUtil.getConnection()) {
                        String sql = "SELECT avatar_url FROM rjgc_users WHERE id = ?";
                        PreparedStatement pstmt = conn.prepareStatement(sql);
                        pstmt.setInt(1, (Integer) session.getAttribute("userId"));
                        ResultSet rs = pstmt.executeQuery();
                        if (rs.next()) {
                            avatarUrl = rs.getString("avatar_url") != null ? rs.getString("avatar_url") : "../images/profile-default.jpg";
                        }
                    } catch (Exception e) {
                        e.printStackTrace();
                    }
                %>
                <img src="<%= request.getContextPath() %><%= avatarUrl %>" class="rounded-circle profile-img mx-auto" alt="头像">

                <h4 class="mt-3"><%= session.getAttribute("username") %></h4>
                <p>普通读者</p>
                <a href="edit_profile.jsp" class="btn btn-outline-primary">编辑个人信息</a>
            </div>
        </div>
        <div class="col-md-8">
            <div class="row">




            <div class="row">
                <div class="col-md-6 mb-4">
                    <div class="card p-4 text-center bg-primary text-white">
                        <i class="fas fa-book fa-3x mb-3"></i>
                        <h3>当前借阅</h3>
                        <h2>
                            <%
                                try (Connection conn = DBUtil.getConnection()) {
                                    PreparedStatement pstmt = conn.prepareStatement("SELECT COUNT(*) FROM rjgc_borrow_records WHERE user_id = ? AND status = '借阅中'");
                                    pstmt.setInt(1, (Integer) session.getAttribute("userId"));
                                    ResultSet rs = pstmt.executeQuery();
                                    if (rs.next()) {
                                        out.print(rs.getInt(1));
                                    } else {
                                        out.print("0");
                                    }
                                } catch (Exception e) {
                                    out.print("0");
                                    e.printStackTrace();
                                }
                            %>
                            本
                        </h2>
                    </div>
                </div>
                <div class="col-md-6 mb-4">
                    <div class="card p-4 text-center bg-success text-white">
                        <i class="fas fa-history fa-3x mb-3"></i>
                        <h3>历史借阅</h3>
                        <h2>
                            <%
                                try (Connection conn = DBUtil.getConnection()) {
                                    PreparedStatement pstmt = conn.prepareStatement("SELECT COUNT(*) FROM rjgc_borrow_records WHERE user_id = ? AND status = '已归还'");
                                    pstmt.setInt(1, (Integer) session.getAttribute("userId"));
                                    ResultSet rs = pstmt.executeQuery();
                                    if (rs.next()) {
                                        out.print(rs.getInt(1));
                                    } else {
                                        out.print("0");
                                    }
                                } catch (Exception e) {
                                    out.print("0");
                                    e.printStackTrace();
                                }
                            %>
                            本
                        </h2>
                    </div>
                </div>
            </div>




            </div>
            <div class="card p-4">
                <h5>最近借阅记录</h5>
                <table class="table table-hover">
                    <thead><tr><th>图书</th><th>借阅日期</th><th>应还日期</th><th>状态</th></tr></thead>
                    <tbody>
                    <%
                        try (Connection conn = DBUtil.getConnection()) {
                            String sql = "SELECT br.*, b.title FROM rjgc_borrow_records br JOIN rjgc_books b ON br.book_id = b.id WHERE br.user_id = ? ORDER BY borrow_date DESC LIMIT 5";
                            PreparedStatement pstmt = conn.prepareStatement(sql);
                            pstmt.setInt(1, (Integer) session.getAttribute("userId"));
                            ResultSet rs = pstmt.executeQuery();
                            boolean hasRecords = false;
                            while (rs.next()) {
                                hasRecords = true;
                    %>
                    <tr>
                        <td><%= rs.getString("title") %></td>
                        <td><%= rs.getDate("borrow_date") %></td>
                        <td><%= rs.getDate("due_date") %></td>
                        <td><%= rs.getString("status") %></td>
                    </tr>
                    <%
                            }
                            if (!hasRecords) {
                    %>
                    <tr>
                        <td colspan="4" class="text-center">暂无借阅记录</td>
                    </tr>
                    <%
                            }
                        } catch (Exception e) {
                            e.printStackTrace();
                    %>
                    <tr>
                        <td colspan="4" class="text-center">查询借阅记录出错</td>
                    </tr>
                    <%
                        }
                    %>
                    </tbody>
                </table>
            </div>
        </div>
    </div>
</div>
<script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/js/bootstrap.bundle.min.js"></script>
</body>
</html>
