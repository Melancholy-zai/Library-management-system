<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ page import="java.sql.*" %>
<%@ page import="java.util.*" %>
<%@ page import="com.bookborrow.util.DBUtil" %>

<!DOCTYPE html>
<html lang="zh-CN">
<head>
    <meta charset="UTF-8">
    <title>反馈评价</title>

    <!-- Bootstrap -->
    <link rel="stylesheet"
          href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/css/bootstrap.min.css">

    <style>
        body {
            background: linear-gradient(135deg, #e3f2fd, #f8f9fa);
            min-height: 100vh;
        }

        .navbar {
            box-shadow: 0 2px 8px rgba(0,0,0,.08);
        }

        .navbar-brand {
            font-weight: bold;
            font-size: 1.4rem;
            color: #0d6efd !important;
        }

        .card {
            border-radius: 16px;
            box-shadow: 0 10px 30px rgba(0,0,0,.12);
            border: none;
        }

        .card h3 {
            font-weight: 600;
            letter-spacing: 1px;
        }

        .form-label {
            font-weight: 500;
            margin-bottom: 6px;
        }

        .form-control,
        .form-select {
            border-radius: 10px;
            padding: 10px 14px;
        }

        .form-control:focus,
        .form-select:focus {
            border-color: #0d6efd;
            box-shadow: 0 0 0 0.15rem rgba(13,110,253,.25);
        }

        textarea {
            resize: none;
        }

        /* 星级评分 */
        .star-rating {
            display: flex;
            flex-direction: row-reverse;
            justify-content: flex-end;
            gap: 6px;
        }

        .star-rating input {
            display: none;
        }

        .star-rating label {
            font-size: 1.8rem;
            color: #ccc;
            cursor: pointer;
            transition: color .2s;
        }

        .star-rating input:checked ~ label,
        .star-rating label:hover,
        .star-rating label:hover ~ label {
            color: #ffc107;
        }

        .btn-lg {
            padding: 10px 32px;
            border-radius: 30px;
        }
    </style>
</head>

<body>

<!-- 导航栏 -->
<nav class="navbar navbar-expand-lg navbar-light bg-light">
    <div class="container">
        <a class="navbar-brand">图书借阅平台</a>
        <div class="collapse navbar-collapse show">
            <ul class="navbar-nav ms-auto">
                <li class="nav-item"><a class="nav-link" href="dashboard.jsp">个人中心</a></li>
                <li class="nav-item"><a class="nav-link" href="book_list.jsp">图书浏览</a></li>
                <li class="nav-item"><a class="nav-link" href="borrow_list.jsp">借阅记录</a></li>
                <li class="nav-item"><a class="nav-link active" href="feedback.jsp">反馈评价</a></li>
                <li class="nav-item"><a class="nav-link" href="../logoutServlet">退出</a></li>
            </ul>
        </div>
    </div>
</nav>

<%
    Integer userId = (Integer) session.getAttribute("userId");

    List<Map<String, Object>> bookList = new ArrayList<>();

    if (userId != null) {
        try (Connection conn = DBUtil.getConnection();
             PreparedStatement ps = conn.prepareStatement(
                     "SELECT DISTINCT b.id, b.title " +
                             "FROM rjgc_books b " +
                             "JOIN rjgc_borrow_records r ON b.id = r.book_id " +
                             "WHERE r.user_id = ? AND r.status = '已归还'")
        ) {
            ps.setInt(1, userId);
            ResultSet rs = ps.executeQuery();
            while (rs.next()) {
                Map<String, Object> book = new HashMap<>();
                book.put("id", rs.getInt("id"));
                book.put("title", rs.getString("title"));
                bookList.add(book);
            }
        } catch (Exception e) {
            e.printStackTrace();
        }
    }

    String error = request.getParameter("error");
    String msg = request.getParameter("msg");
%>

<div class="container my-5" style="max-width: 720px;">
    <div class="card p-4">
        <h3 class="text-center mb-4">提交阅读反馈</h3>

        <% if (error != null) { %>
        <div class="alert alert-danger text-center"><%= error %></div>
        <% } %>

        <% if (msg != null) { %>
        <div class="alert alert-success text-center"><%= msg %></div>
        <% } %>

        <form action="../feedbackServlet" method="post">

            <!-- 图书选择 -->
            <div class="mb-3">
                <label class="form-label">选择图书</label>
                <select name="bookId" class="form-select" required>
                    <option value="">请选择已归还的图书</option>
                    <% if (bookList.isEmpty()) { %>
                    <option disabled>暂无可反馈的图书</option>
                    <% } else {
                        for (Map<String,Object> b : bookList) { %>
                    <option value="<%= b.get("id") %>">
                        <%= b.get("title") %>
                    </option>
                    <%   }
                    } %>
                </select>
            </div>

            <!-- 星级评分 -->
            <div class="mb-4">
                <label class="form-label">评价星级</label>
                <div class="star-rating">
                    <input type="radio" name="rating" id="star5" value="5" required>
                    <label for="star5">★</label>

                    <input type="radio" name="rating" id="star4" value="4">
                    <label for="star4">★</label>

                    <input type="radio" name="rating" id="star3" value="3">
                    <label for="star3">★</label>

                    <input type="radio" name="rating" id="star2" value="2">
                    <label for="star2">★</label>

                    <input type="radio" name="rating" id="star1" value="1">
                    <label for="star1">★</label>
                </div>
            </div>

            <!-- 评论 -->
            <div class="mb-3">
                <label class="form-label">评论内容</label>
                <textarea name="comment"
                          class="form-control"
                          rows="5"
                          maxlength="500"
                          placeholder="请输入你的阅读感受（最多500字）"
                          required></textarea>
            </div>

            <!-- 按钮 -->
            <div class="d-flex justify-content-center gap-4 mt-4">
                <button class="btn btn-primary btn-lg">提交反馈</button>
                <a href="borrow_list.jsp" class="btn btn-outline-secondary btn-lg">返回</a>
            </div>

        </form>
    </div>
</div>

<script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/js/bootstrap.bundle.min.js"></script>
</body>
</html>
