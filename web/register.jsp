<!-- register.jsp (进一步美化版) -->
<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<!DOCTYPE html>
<html lang="zh-CN">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>注册 - 线上图书借阅平台</title>
    <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/css/bootstrap.min.css">
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.0/css/all.min.css">
    <style>
        body {
            background-image: url('images/register-bg.jpg'); /* 用[image:4]下载保存 */
            background-size: cover;
            background-position: center;
            height: 100vh;
            display: flex;
            align-items: center;
            justify-content: center;
            font-family: 'Arial', sans-serif;
            overflow: hidden;
        }
        .register-form {
            max-width: 420px;
            padding: 50px 40px;
            background: rgba(255, 255, 255, 0.9);
            border-radius: 20px;
            box-shadow: 0 10px 40px rgba(0, 0, 0, 0.25);
            animation: fadeInUp 1s ease-out;
            position: relative;
            z-index: 1;
        }
        @keyframes fadeInUp {
            from { opacity: 0; transform: translateY(50px); }
            to { opacity: 1; transform: translateY(0); }
        }
        .form-control { border-radius: 10px; padding: 12px; }
        .btn-primary { border-radius: 10px; padding: 12px; transition: background 0.3s, box-shadow 0.3s; }
        .btn-primary:hover { background: #28a745; box-shadow: 0 0 20px rgba(40, 167, 69, 0.5); } /* 绿色调配注册 */
        .input-group-text { border-radius: 10px 0 0 10px; background: linear-gradient(to right, #f8f9fa, #e9ecef); }
        .alert { border-radius: 10px; animation: shake 0.5s; }
        @keyframes shake { 0%, 100% { transform: translateX(0); } 25% { transform: translateX(-5px); } 75% { transform: translateX(5px); } }
    </style>
</head>
<body>
<div class="register-form">
    <h2 class="text-center mb-4"><i class="fas fa-user-plus fa-beat me-2" style="color: #28a745;"></i>用户注册</h2>

    <%-- 提示语显示 --%>
    <%
        String error = request.getParameter("error");
        String msg = request.getParameter("msg");
        if (error != null) {
    %>
    <div class="alert alert-danger"><%= error %></div>
    <%
    } else if (msg != null) {
    %>
    <div class="alert alert-success"><%= msg %></div>
    <%
        }
    %>

    <form action="registerServlet" method="post">
        <div class="input-group mb-3">
            <span class="input-group-text"><i class="fas fa-user"></i></span>
            <input type="text" class="form-control" name="username" placeholder="用户名" required>
        </div>
        <div class="input-group mb-3">
            <span class="input-group-text"><i class="fas fa-envelope"></i></span>
            <input type="email" class="form-control" name="email" placeholder="邮箱" required>
        </div>
        <div class="input-group mb-3">
            <span class="input-group-text"><i class="fas fa-key"></i></span>
            <input type="password" class="form-control" name="password" placeholder="密码" required>
        </div>
        <div class="input-group mb-3">
            <span class="input-group-text"><i class="fas fa-phone"></i></span>
            <input type="text" class="form-control" name="emergencyContact" placeholder="紧急联系人">
        </div>
        <button type="submit" class="btn btn-primary w-100">注册</button>
    </form>
    <p class="text-center mt-3">已有账号？<a href="login.jsp">登录</a></p>
</div>
<script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/js/bootstrap.bundle.min.js"></script>
</body>
</html>