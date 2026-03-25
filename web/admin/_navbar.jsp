<%@ page language="java" pageEncoding="UTF-8" contentType="text/html; charset=UTF-8" %>
<nav class="navbar navbar-expand-lg navbar-dark bg-dark">
    <div class="container">
        <a class="navbar-brand" href="dashboard.jsp">管理员</a>
        <button class="navbar-toggler" type="button" data-bs-toggle="collapse" data-bs-target="#adminNav">
            <span class="navbar-toggler-icon"></span>
        </button>
        <div class="collapse navbar-collapse" id="adminNav">
            <ul class="navbar-nav ms-auto">
                <li class="nav-item"><a class="nav-link" href="dashboard.jsp">首页</a></li>
                <li class="nav-item"><a class="nav-link" href="book_manage.jsp">图书管理</a></li>
                <li class="nav-item"><a class="nav-link" href="borrow_manage.jsp">借阅管理</a></li>
                <li class="nav-item"><a class="nav-link" href="statistics.jsp">数据统计</a></li>
                <li class="nav-item"><a class="nav-link text-warning" href="../logoutServlet">退出</a></li>
            </ul>
        </div>
    </div>
</nav>
