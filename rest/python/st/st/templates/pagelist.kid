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
                <th>Title</th>
                <th>Revision Count</th>
                <th>Last Modified</th>
                <th>Edited By</th>
                <th>Tags</th>
            </tr>
            <tr py:for="page in pages">
                <td><a href="${tg.url('/page/' + page['name'])}" py:content="page['name']">Page Name Here.</a></td> 
                <td py:content="page['revision_count']">Revision Count</td>
                <td py:content="page['last_edit_time']">Last Edit</td>
                <td py:content="page['last_editor']">Last Editor</td>
                <td>
                    <ul>
                        <li py:for="tag in page['tags']"> 
                        <a href="${tg.url('/tagged/' + tag)}" py:content="tag">Tag Name Here</a>
                        </li>
                    </ul>
                </td>
            </tr> 
        </table>
    </div>

</body>
</html>
