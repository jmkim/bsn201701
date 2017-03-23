<%--
  Created by IntelliJ IDEA.
  User: jmkim
  Date: 2/9/17
  Time: 1:32 PM
--%>
<%@ page language="java" contentType="text/html; charset=UTF-8"
         import="java.sql.*, javax.naming.*, javax.sql.*, java.text.DecimalFormat, java.util.UUID" %>
<%!
    private static DecimalFormat formatter = new DecimalFormat("00.00");

    private final String page_title = "부산광역시 중·고등학교 학업성취도 조회";
    private final String page_title_no_wrap = "부산광역시 <wbr>중·고등학교 <wbr>학업성취도 조회"; // 문장이 가로폭보다 길 때 끊는 부분(<wbr>) 포함
    private final int yearRangeStart = 2014;
    private final int yearRangeEnd = 2016;

    class ErrorHtml {
        String key;
        StringBuilder html;
        StringBuilder console;

        ErrorHtml(Exception e) {
            key = UUID.randomUUID().toString();

            console = new StringBuilder();
            console.append("ERROR:\n");
            console.append("\tLOG_ID: ");
            console.append(key);
            console.append("\n\t");
            console.append(e.toString());
            console.append("\n");

            html = new StringBuilder();
            html.append("    <section class=\"text-center\">\n");
            html.append("        <h5><span class=\"text-danger\">이런! 서버에 오류가 발생했어요…</span></h5>\n");
            html.append("        <p>죄송합니다!\n");
            html.append("            <br>빠르게 고칠 수 있도록 <a\n");
            html.append("                href=\"mailto:jmkim@pukyong.ac.kr?Subject=%EB%B6%80%EC%82%B0%EA%B4%91%EC%97%AD%EC%8B%9C%20%EC%A4%91%C2%B7%EA%B3%A0%EB%93%B1%ED%95%99%EA%B5%90%20%ED%95%99%EC%97%85%EC%84%B1%EC%B7%A8%EB%8F%84%20%EC%A1%B0%ED%9A%8C%20%EC%98%A4%EB%A5%98%20%EB%B3%B4%EA%B3%A0&body=LOG%20ID%3A%20");
            html.append(key);
            html.append("\">관리자에게\n");
            html.append("        메일을 보내주세요</a>.\n");
            html.append("            <br>\n");
            html.append("            <small>LOG ID: <span class=\"text-monospace\">");
            html.append(key);
            html.append("</span></small>\n");
            html.append("        </p>\n");
            html.append("    </section>\n");
        }

        public String print() {
            System.err.print(console.toString());
            return (html.toString());
        }

        @Override
        public String toString() {
            return (console.toString());
        }
    }

    class School {
        private String name;
        private ResultSet rs;

        School(String name, ResultSet rs) {
            this.name = name;
            this.rs = rs;
        }

        private Object getObjectFromResultSet(String columnName) {
            try {
                return (rs.getObject(columnName));
            } catch (SQLException e) {
                //Logger::write ("ERROR: ");
                return (null);
            }
        }

        public String getName() {
            return (name);
        }

        public String getCategory() throws SQLException {
            return rs.getString("CAT").charAt(0) == 'P' ? "공립" : "사립";
        }

        public String getType() throws SQLException {
            return rs.getString("TYPE");
        }

        public String getAddressGu() throws SQLException {
            return (rs.getString("GU"));
        }

        public String getAddressDong() throws SQLException {
            return (rs.getString("DONG"));
        }

        public String getAddress() throws SQLException {
            return (getAddressGu() + " " + getAddressDong());
        }

        public String getScoreKorean(int year) throws SQLException {
            return (formatter.format(rs.getFloat("K" + Integer.toString(year)) * 100));
        }

        public String getScoreEnglish(int year) throws SQLException {
            return (formatter.format(rs.getFloat("E" + Integer.toString(year)) * 100));
        }

        public String getScoreMath(int year) throws SQLException {
            return (formatter.format(rs.getFloat("M" + Integer.toString(year)) * 100));
        }

        public String getInfo() throws SQLException {
            return (getName() + " <small>(" + getCategory() + ", " + getAddress() + ")</small>");
        }
    }
%>
<%
    request.setCharacterEncoding("UTF-8");

    String name = request.getParameter("name");
    name = (name == null) ? "" : name;
%>
<!DOCTYPE html>
<html lang="ko">
<head>
    <meta charset="UTF-8">
    <meta name="description" content="<%= page_title %>">
    <meta name="keywords" content="부산,중학교,고등학교,학업성취도">
    <meta name="author"
          content="Ha-Joo Song <hajoosong@pknu.ac.kr>, Jongmin Kim <jmkim@pukyong.ac.kr>, Ho-Jun Kim <wlrhkvlf23@gmail.com>">
    <meta name="viewport" content="width=device-width, initial-scale=1, maximum-scale=1, user-scalable=no">
    <meta http-equiv="x-ua-compatible" content="IE=edge">

    <title><%= page_title %>
    </title>

    <link rel="stylesheet" href="./css/bootstrap.min.css">
    <link rel="stylesheet" href="./css/tether.min.css">
    <link rel="stylesheet" href="css/bsn201701.css">
</head>

<body>
<!-- 컨텐츠의 시작 -->
<div class="container">
    <!-- Header의 시작 -->
    <header>
        <h3><a class="text-primary text-no-wrap" href="./"><%= page_title_no_wrap %>
        </a></h3>
    </header>
    <!-- Header의 끝 -->

    <!-- 조회 입력 폼의 시작 -->
    <section>
        <form method="post" action>
            <div class="form-group">
                <div class="input-group">
                    <input class="form-control" type="text" name="name" placeholder="학교명 입력" value="<%= name %>"
                           autofocus> <!-- 학교명 입력 input -->
                    <span class="input-group-btn">
                        <button class="btn btn-primary" type="submit">조회</button> <!-- 조회 button -->
                    </span>
                </div>
                <small class="text-muted">입력 예시: '부산고', '부산중'</small>
            </div>
        </form>
    </section>
    <!-- 조회 입력 폼의 끝 -->
    <%
        if (name.length() > 0) {
    %>
    <!-- 결과 화면의 시작 -->
    <%
        Context ctx = null;
        Connection con = null;

        PreparedStatement schoolPs = null;
        PreparedStatement countPs = null;
        PreparedStatement avgPs = null;
        ResultSet schoolRs = null;
        ResultSet countRs = null;
        ResultSet avgRs = null;


        try {
            ctx = new InitialContext();
            con = ((DataSource) ctx.lookup("java:comp/env/jdbc/bsn")).getConnection();

            schoolPs = con.prepareStatement("SELECT * FROM SCHOOL_ACHIEVEMENT WHERE NAME = ?");
            countPs = con.prepareStatement("SELECT COUNT(*) AS COUNT FROM SCHOOL_ACHIEVEMENT WHERE TYPE = ?");
            avgPs = con.prepareStatement("SELECT AVG(K2016) AS K2016, AVG(K2015) AS K2015, AVG(K2014) AS K2014, AVG(E2016) AS E2016, AVG(E2015) AS E2015, AVG(E2014) AS E2014, AVG(M2016) AS M2016, AVG(M2015) AS M2015, AVG(M2014) AS M2014 FROM SCHOOL_ACHIEVEMENT WHERE TYPE = ?");

            schoolPs.setString(1, name);
            schoolRs = schoolPs.executeQuery();

            if (schoolRs.next()) {
                School school = new School(name, schoolRs);

                countPs.setString(1, school.getType());
                countRs = countPs.executeQuery();

                countRs.next();

                avgPs.setString(1, school.getType());
                avgRs = avgPs.executeQuery();

                avgRs.next();
                School avg = new School("", avgRs);
    %>
    <section>
        <h3><%= school.getInfo() %>
        </h3>
    </section>

    <section>
        <h5>보통 학력 이상 학생의 비율</h5>
        <table class="table">
            <tr>
                <th>연도</th>
                <%
                    for (int year = yearRangeEnd; year >= yearRangeStart; --year) {
                %>
                <th><%= year %>
                </th>
                <%
                    }
                %>
            </tr>
            <tr>
                <th>국어</th>
                <%
                    for (int year = yearRangeEnd; year >= yearRangeStart; --year) {
                %>
                <td><%= school.getScoreKorean(year) %> (<%= avg.getScoreKorean(year) %>)</td>
                <%
                    }
                %>
            </tr>
            <tr>
                <th>수학</th>
                <%
                    for (int year = yearRangeEnd; year >= yearRangeStart; --year) {
                %>
                <td><%= school.getScoreMath(year) %> (<%= avg.getScoreMath(year) %>)</td>
                <%
                    }
                %>
            </tr>
            <tr>
                <th>영어</th>
                <%
                    for (int year = yearRangeEnd; year >= yearRangeStart; --year) {
                %>
                <td><%= school.getScoreEnglish(year) %> (<%= avg.getScoreEnglish(year) %>)</td>
                <%
                    }
                %>
            </tr>
        </table>
        <div class="row">
            <div class="col-lg-12 text-right">
                <small class="text-muted">단위: %, 괄호 안의 값은 부산광역시에 소재한 <%= countRs.getString("COUNT") %>개 학교의 평균
                </small>
            </div>
        </div>
    </section>
    <%
    } else {
    %>
    <section class="text-center">
        <h5>학교명 <span class="text-danger"><%= name %></span>을(를) 찾을 수 없습니다.</h5>
        <p>검색이 안될 경우 학교명 앞에 <strong>부산</strong>을 붙여 보세요.</p>
    </section>
    <%
        }
    %>
    <!-- 결과 화면의 끝 -->
    <%
            } catch (Exception e) {
                ErrorHtml error = new ErrorHtml(e);
                out.print(error.print());
            } finally {
                try {
                    schoolRs.close();
                    countRs.close();
                    avgRs.close();
                    schoolPs.close();
                    countPs.close();
                    avgPs.close();
                    con.close();
                    ctx.close();
                } catch (Exception e) {
                }
            }
        }
    %>

    <!-- Footer의 시작 -->
    <footer class="text-muted text-center">
        <p>Developed by <a class="text-muted" href="mailto:jmkim@pukyong.ac.kr">Jongmin Kim</a> &amp; <a
                class="text-muted" href="mailto:wlrhkvlf23@gmail.com">Ho-Jun Kim</a></p>
        <p><a class="text-muted" href="http://db.pknu.ac.kr">Information &amp; Database Systems Laboratory</a><br><a
                class="text-muted" href="http://www.pknu.ac.kr">Pukyong National University</a></p>
    </footer>
    <!-- Footer의 끝 -->
</div>
<!-- 컨텐츠의 끝 -->

<script type="text/javascript" src="./js/jquery-3.1.1.min.js"></script>
<script type="text/javascript" src="./js/tether.min.js"></script>
<script type="text/javascript" src="./js/bootstrap.min.js"></script>
<script>
    (function(i,s,o,g,r,a,m){i['GoogleAnalyticsObject']=r;i[r]=i[r]||function(){
    (i[r].q=i[r].q||[]).push(arguments)},i[r].l=1*new Date();a=s.createElement(o),
    m=s.getElementsByTagName(o)[0];a.async=1;a.src=g;m.parentNode.insertBefore(a,m)
    })(window,document,'script','https://www.google-analytics.com/analytics.js','ga');
    ga('create', 'UA-91494408-1', 'auto');
    ga('send', 'pageview');
</script>
</body>
</html>
