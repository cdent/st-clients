<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html xmlns="http://www.w3.org/1999/xhtml" xmlns:py="http://purl.org/kid/ns#"
    py:extends="'master.kid'">
<head>
<meta content="text/html; charset=utf-8" http-equiv="Content-Type" py:replace="''"/>
<title>${title} - Hello</title>
</head>
<body>

    <div class="main_content">
        <h1>${title}</h1>
        <table border="1">
            <tr>
                <th>Tag</th>
                <th>Count</th>
            </tr>
            <tr py:for="tag in tags">
                <td><a href="${tg.url('/tagged/' + tag['name'])}" py:content="tag['name']">Tag Name Here.</a></td> 
                <td py:content="tag['page_count']">Tagn Count</td>
            </tr> 
        </table>
    </div>

</body>
</html>
