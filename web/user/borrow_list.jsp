<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ page import="java.sql.*" %>
<%@ page import="com.bookborrow.util.DBUtil" %>
<!DOCTYPE html>
<html lang="zh-CN">
<head>
    <meta charset="UTF-8">
    <title>借阅记录</title>
    <link rel="stylesheet"
          href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/css/bootstrap.min.css">

    <style>
        .book-thumb {
            width: 60px;
            height: 90px;
            object-fit: cover;
            border-radius: 6px;
        }
        .status-overdue {
            color: #dc3545;
            font-weight: bold;
        }
        .status-borrowing {
            color: #0d6efd;
            font-weight: bold;
        }
    </style>
</head>
<body>

<!-- 顶部导航 -->
<nav class="navbar navbar-expand-lg navbar-light bg-light shadow-sm">
    <div class="container">
        <a class="navbar-brand fw-bold" href="#">图书借阅平台</a>
        <div class="collapse navbar-collapse">
            <ul class="navbar-nav ms-auto">
                <li class="nav-item"><a class="nav-link" href="dashboard.jsp">个人中心</a></li>
                <li class="nav-item"><a class="nav-link" href="book_list.jsp">图书浏览</a></li>
                <li class="nav-item"><a class="nav-link active" href="#">借阅记录</a></li>
                <li class="nav-item"><a class="nav-link" href="feedback.jsp">反馈评价</a></li>
                <li class="nav-item"><a class="nav-link" href="../logoutServlet">退出</a></li>
            </ul>
        </div>
    </div>
</nav>

<div class="container my-5">
    <h2 class="text-center mb-4">📚 我的借阅记录</h2>

    <%
        Integer userId = (Integer) session.getAttribute("userId");
        if (userId == null) {
            response.sendRedirect("../login.jsp");
            return;
        }

        int borrowLimit = 0;
        int currentBorrowed = 0;

        try (Connection conn = DBUtil.getConnection()) {

            // 借阅上限
            PreparedStatement p1 =
                    conn.prepareStatement("SELECT borrow_limit FROM rjgc_users WHERE id=?");
            p1.setInt(1, userId);
            ResultSet r1 = p1.executeQuery();
            if (r1.next()) borrowLimit = r1.getInt(1);

            // 当前借阅数
            PreparedStatement p2 =
                    conn.prepareStatement(
                            "SELECT COUNT(*) FROM rjgc_borrow_records " +
                                    "WHERE user_id=? AND status IN ('借阅中','逾期')");
            p2.setInt(1, userId);
            ResultSet r2 = p2.executeQuery();
            if (r2.next()) currentBorrowed = r2.getInt(1);
    %>

    <!-- 借阅提示 -->
    <div class="alert alert-info text-center">
        当前借阅 <strong><%= currentBorrowed %></strong> 本，
        借阅上限 <strong><%= borrowLimit %></strong> 本，
        还可借 <strong><%= Math.max(0, borrowLimit - currentBorrowed) %></strong> 本
    </div>

    <table class="table table-bordered table-hover align-middle">
        <thead class="table-primary">
        <tr class="text-center">
            <th>封面</th>
            <th>书名</th>
            <th>借阅日期</th>
            <th>应还日期</th>
            <th>状态</th>
            <th width="220">操作</th>
        </tr>
        </thead>
        <tbody>

        <%
            String sql =
                    "SELECT br.id, br.book_id, br.borrow_date, br.due_date, br.status, " +
                            "b.title, b.cover_url " +
                            "FROM rjgc_borrow_records br " +
                            "JOIN rjgc_books b ON br.book_id=b.id " +
                            "WHERE br.user_id=? ORDER BY br.id DESC";

            PreparedStatement ps = conn.prepareStatement(sql);
            ps.setInt(1, userId);
            ResultSet rs = ps.executeQuery();

            boolean hasData = false;
            while (rs.next()) {
                hasData = true;
                int recordId = rs.getInt("id");
                int bookId = rs.getInt("book_id");
                String title = rs.getString("title");
                String cover = rs.getString("cover_url");
                if (cover == null || cover.isEmpty()) cover = "../images/default-book.jpg";
                Date borrowDate = rs.getDate("borrow_date");
                Date dueDate = rs.getDate("due_date");
                String status = rs.getString("status");
        %>

        <tr class="text-center">
            <td><img src="<%= cover %>" class="book-thumb"></td>
            <td><%= title %></td>
            <td><%= borrowDate == null ? "-" : borrowDate %></td>
            <td><%= dueDate == null ? "-" : dueDate %></td>
            <td class="<%= "逾期".equals(status) ? "status-overdue" :
                           "借阅中".equals(status) ? "status-borrowing" : "" %>">
                <%= status %>
            </td>
            <td>
                <% if ("借阅中".equals(status) || "逾期".equals(status)) { %>
                <button class="btn btn-sm btn-warning"
                        onclick="returnBook(<%= recordId %>)">归还</button>
                <% } else { %>
                <span class="text-muted">不可操作</span>
                <% } %>

                <% if (!"待审核".equals(status)) { %>
                <a href="feedback.jsp?bookId=<%= bookId %>"
                   class="btn btn-sm btn-info ms-1">反馈</a>
                <% } %>
            </td>
        </tr>

        <%
            }
            if (!hasData) {
        %>
        <tr>
            <td colspan="6" class="text-center text-muted">暂无借阅记录</td>
        </tr>
        <%
            }
        %>

        </tbody>
    </table>

    <%
        } catch (Exception e) {
            e.printStackTrace();
        }
    %>
</div>

<script>
    async function returnBook(recordId) {
        if (!confirm("确认归还该图书吗？")) return;

        try {
            const res = await fetch("../returnServlet", {
                method: "POST",
                headers: {
                    "Content-Type": "application/x-www-form-urlencoded"
                },
                body: "recordId=" + encodeURIComponent(recordId)
            });

            const data = await res.json();
            alert(data.message);
            if (data.success) location.reload();
        } catch (e) {
            alert("归还失败");
        }
    }
</script>

</body>
</html>
