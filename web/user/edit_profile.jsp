<!-- user/edit_profile.jsp -->
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
    .profile-img {
        width: 150px;
        height: 150px;
        border-radius: 50%;
        object-fit: cover;
        border: 4px solid #007bff;
        box-shadow: 0 4px 15px rgba(0,0,0,0.1);
    }
    .btn-outline-primary {
        border-radius: 50px;
        padding: 0.5rem 1.5rem;
        font-weight: 500;
    }
    .form-control {
        border-radius: 50px;
    }
</style>



    <meta charset="UTF-8">
    <title>编辑个人信息</title>
    <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/css/bootstrap.min.css">
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.0/css/all.min.css">
    <style>
        body { background: #f8f9fa; }
        .profile-form { max-width: 500px; margin: auto; padding: 40px; background: white; border-radius: 15px; box-shadow: 0 4px 20px rgba(0,0,0,0.1); }
        .profile-img { width: 150px; height: 150px; border-radius: 50%; object-fit: cover; border: 4px solid #007bff; }
        .form-group { margin-bottom: 1rem; }
    </style>
</head>
<body>
<div class="container my-5">
    <div class="profile-form">
        <h2 class="text-center mb-4"><i class="fas fa-user-edit me-2"></i>编辑个人信息</h2>

        <%
            Integer userId = (Integer) session.getAttribute("userId");
            String currentUsername = "";
            String currentEmail = "";
            String currentPhone = "";
            String currentEmergency = "";
            String currentAvatar = "../images/default-avatar.jpg";

            try (Connection conn = DBUtil.getConnection()) {
                String sql = "SELECT username, email, phone, emergency_contact, avatar_url FROM rjgc_users WHERE id = ?";
                PreparedStatement pstmt = conn.prepareStatement(sql);
                pstmt.setInt(1, userId);
                ResultSet rs = pstmt.executeQuery();
                if (rs.next()) {
                    currentUsername = rs.getString("username");
                    currentEmail = rs.getString("email");
                    currentPhone = rs.getString("phone");
                    currentEmergency = rs.getString("emergency_contact");
                    currentAvatar = rs.getString("avatar_url") != null ? rs.getString("avatar_url") : "../images/default-avatar.jpg";
                }
            } catch (Exception e) {
                e.printStackTrace();
            }
        %>

        <form action="<%= request.getContextPath() %>/editProfileServlet" method="post" enctype="multipart/form-data">
            <!-- 头像上传 -->
            <div class="text-center mb-4">
                <img src="<%= request.getContextPath() %><%= currentAvatar %>" class="profile-img" alt="头像">

                <div class="mt-3">
                    <label class="btn btn-outline-primary">
                        <i class="fas fa-upload me-2"></i>上传新头像
                        <input type="file" name="avatar" hidden accept="image/*">
                    </label>
                </div>
            </div>

            <!-- 用户名 -->
            <div class="form-group">
                <label for="username" class="form-label">用户名</label>
                <input type="text" class="form-control" id="username" name="username" value="<%= currentUsername %>" required>
            </div>

            <!-- 邮箱 -->
            <div class="form-group">
                <label for="email" class="form-label">邮箱</label>
                <input type="email" class="form-control" id="email" name="email" value="<%= currentEmail %>" required>
            </div>

            <!-- 手机号 -->
            <div class="form-group">
                <label for="phone" class="form-label">手机号</label>
                <input type="tel" class="form-control" id="phone" name="phone" value="<%= currentPhone %>" required>
            </div>

            <!-- 紧急联系人 -->
            <div class="form-group">
                <label for="emergency" class="form-label">紧急联系人</label>
                <input type="text" class="form-control" id="emergency" name="emergency" value="<%= currentEmergency %>" placeholder="输入紧急联系人">
            </div>


            <button type="submit" class="btn btn-primary w-100">保存更改</button>
        </form>

        <p class="text-center mt-3"><a href="dashboard.jsp">返回个人中心</a></p>
    </div>
</div>
<script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/js/bootstrap.bundle.min.js"></script>
</body>
</html>
