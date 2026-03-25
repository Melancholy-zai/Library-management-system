<!-- index.jsp -->
<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<!DOCTYPE html>
<html lang="zh-CN">
<head>
  <meta charset="UTF-8">
  <title>线上图书借阅平台 - 首页</title>
  <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/css/bootstrap.min.css">
  <style>
    body { background-color: #f8f9fa; font-family: 'Arial', sans-serif; }
    .hero { background-image: url('images/hero-bg.jpg'); background-size: cover; color: white; padding: 100px 0; text-align: center; }
    .card { margin-bottom: 20px; transition: transform 0.3s; }
    .card:hover { transform: scale(1.05); }
  </style>
</head>
<body>
<nav class="navbar navbar-expand-lg navbar-light bg-light">
  <div class="container-fluid">
    <a class="navbar-brand" href="#">图书借阅平台</a>
    <button class="navbar-toggler" type="button" data-bs-toggle="collapse" data-bs-target="#navbarNav">
      <span class="navbar-toggler-icon"></span>
    </button>
    <div class="collapse navbar-collapse" id="navbarNav">
      <ul class="navbar-nav ms-auto">
        <li class="nav-item"><a class="nav-link" href="login.jsp">登录</a></li>
        <li class="nav-item"><a class="nav-link" href="register.jsp">注册</a></li>
      </ul>
    </div>
  </div>
</nav>

<div class="hero">
  <h1>欢迎来到线上图书借阅平台</h1>
  <p>便捷检索、预约借阅，享受阅读乐趣</p>
  <a href="login.jsp" class="btn btn-primary btn-lg">立即开始</a>
</div>

<div class="container my-5">
  <h2 class="text-center">平台特色</h2>
  <div class="row">
    <style>
      .feature-img {
        height: 250px;          /* 固定高度，所有图片统一 */
        object-fit: cover;      /* 裁剪填充，不变形 */
        object-position: center; /* 焦点居中 */
      }
      .card {
        height: 100%;           /* 卡片高度自适应 */
        display: flex;
        flex-direction: column;
      }
      .card-body {
        flex-grow: 1;           /* 文字部分均匀拉伸 */
      }
    </style>
    <div class="col-md-4">
      <div class="card">
        <img src="images/feature1.jpg" class="card-img-top feature-img" alt="图书浏览与借阅">
        <div class="card-body">
          <h5 class="card-title">图书浏览与借阅</h5>
          <p class="card-text">按分类浏览，搜索ISBN，轻松借阅。</p>
        </div>
      </div>
    </div>
    <div class="col-md-4">
      <div class="card">
        <img src="images/feature2.jpg" class="card-img-top feature-img" alt="借阅跟踪">
        <div class="card-body">
          <h5 class="card-title">借阅跟踪</h5>
          <p class="card-text">接收通知，在线续借，提交反馈。</p>
        </div>
      </div>
    </div>
    <div class="col-md-4">
      <div class="card">
        <img src="images/feature3.jpg" class="card-img-top feature-img" alt="管理与统计">
        <div class="card-body">
          <h5 class="card-title">管理与统计</h5>
          <p class="card-text">管理员高效管理图书与借阅。</p>
        </div>
      </div>
    </div>
  </div>
</div>

<footer class="bg-light text-center py-3">
  <p>&copy; 2025 线上图书借阅平台. All rights reserved.</p>
</footer>

<script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/js/bootstrap.bundle.min.js"></script>
</body>
</html>