﻿<%@ Page Title="ONLYOFFICE" Language="C#" Inherits="System.Web.Mvc.ViewPage<OnlineEditorsExampleMVC.Models.FileModel>" %>
<%@ Import Namespace="System.IO" %>
<%@ Import Namespace="System.Web.Configuration" %>
<%@ Import Namespace="OnlineEditorsExampleMVC.Helpers" %>

<!DOCTYPE html>

<html>
<head runat="server">
    <meta http-equiv="Content-Type" content="text/html; charset=utf-8" />
    <meta http-equiv="X-UA-Compatible" content="IE=edge" />
    <meta name="viewport" content="width=device-width, initial-scale=1, maximum-scale=1, minimum-scale=1, user-scalable=no, minimal-ui" />
    <meta name="apple-mobile-web-app-capable" content="yes" />
    <meta name="mobile-web-app-capable" content="yes" />
    <!--
    *
    * (c) Copyright Ascensio System SIA 2024
    *
    * Licensed under the Apache License, Version 2.0 (the "License");
    * you may not use this file except in compliance with the License.
    * You may obtain a copy of the License at
    *
    *     http://www.apache.org/licenses/LICENSE-2.0
    *
    * Unless required by applicable law or agreed to in writing, software
    * distributed under the License is distributed on an "AS IS" BASIS,
    * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    * See the License for the specific language governing permissions and
    * limitations under the License.
    *
    -->
    <link rel="icon" href="<%= "content/images/" + Model.DocumentType + ".ico" %>" type="image/x-icon" />
    <title><%= Model.FileName + " - ONLYOFFICE" %></title>

    <%: Styles.Render("~/Content/editor") %>

</head>
<body>
    <div class="form">
        <div id="iframeEditor">
        </div>
    </div>

    <%: Scripts.Render(new []{ WebConfigurationManager.AppSettings["files.docservice.url.site"] + WebConfigurationManager.AppSettings["files.docservice.url.api"] }) %>

    <script type="text/javascript" language="javascript">

        var docEditor;
        var config;

        var innerAlert = function (message, inEditor) {
            if (console && console.log)
                console.log(message);
            if (inEditor && docEditor)
                docEditor.showMessage(message);
        };

        // the application is loaded into the browser
        var onAppReady = function () {
            innerAlert("Document editor ready");
        };

        var onSubmit = function () {
            var connector = docEditor.createConnector();
            console.log("onSubmit");

            var results = {}; // Объект для хранения результатов
            var pending = 0;  // Количество оставшихся запросов

            connector.executeMethod("GetAllForms", null, function (data) {
                if (!data || data.length === 0) {
                    console.log(JSON.stringify(results)); // Если нет данных, сразу выводим пустой результат
                    return;
                }

                pending = data.length; // Обновляем количество запросов

                for (let i = 0; i < data.length; i++) {
                    // Для каждого элемента данных выполняем запрос
                    connector.executeMethod("GetFormValue", [data[i]["InternalId"]], function (value) {
                        var fieldName = data[i].Tag;
                        results[fieldName] = value; // Сохраняем результат в объекте

                        pending--;
                        if (pending === 0) {
                            console.log(JSON.stringify(results)); // Выводим результаты, когда все запросы завершены
                        }
                    });
                }
            });
        };

        var onDocumentReady = function () {
            var connector = docEditor.createConnector();
            console.log("onDocumentReady");

            var results = {
                "Serial": "000011",
                "Photo": null,
                "Company Name": "IT Dream",
                "Date": "08.08.2024",
                "Recipient": "John Smith",
                "Qty1": "10",
                "Description1": "Computers",
                "Qty2": "5",
                "Description2": "Monitors",
                "Qty3": "8",
                "Description3": "Printers"
            };

            connector.executeMethod("GetAllForms", null, function (data) {
                if (!data || data.length === 0) {
                    console.log(JSON.stringify(results)); // Если нет данных, сразу выводим пустой результат
                    return;
                }

                for (let i = 0; i < data.length; i++) {
                    // Для каждого элемента данных выполняем запрос
                    // data[i].Tag должен соответствовать ключу в results
                    let value = results[data[i].Tag];
                    if (value !== undefined) { // Проверка, чтобы избежать ошибок, если ключ не найден
                        connector.executeMethod("SetFormValue", [data[i]["InternalId"], value]);
                    } else {
                        console.warn(`No value found for tag: ${data[i].Tag}`);
                    }
                }
            });
        };

        // the document is modified
        var onDocumentStateChange = function (event) {
            console.log("onDocumentStateChange")
            var title = document.title.replace(/\*$/g, "");
            document.title = title + (event.data ? "*" : "");
        };

        // the user is trying to switch the document from the viewing into the editing mode
        var onRequestEditRights = function () {
            location.href = location.href.replace(RegExp("editorsMode=\\w+\&?", "i"), "") + "&editorsMode=edit";
        };

        // an error or some other specific event occurs
        var onError = function (event) {
            if (event)
                innerAlert(event.data);
        };

        // the document is opened for editing with the old document.key value
        var onOutdatedVersion = function (event) {
            location.reload(true);
        };

        // replace the link to the document which contains a bookmark
        var replaceActionLink = function(href, linkParam) {
            var link;
            var actionIndex = href.indexOf("&actionLink=");
            if (actionIndex != -1) {
                var endIndex = href.indexOf("&", actionIndex + "&actionLink=".length);
                if (endIndex != -1) {
                    link = href.substring(0, actionIndex) + href.substring(endIndex) + "&actionLink=" + encodeURIComponent(linkParam);
                } else {
                    link = href.substring(0, actionIndex) + "&actionLink=" + encodeURIComponent(linkParam);
                }
            } else {
                link = href + "&actionLink=" + encodeURIComponent(linkParam);
            }
            return link;
        }

        // the user is trying to get link for opening the document which contains a bookmark, scrolling to the bookmark position
        var onMakeActionLink = function (event) {
            var actionData = event.data;
            var linkParam = JSON.stringify(actionData);
            docEditor.setActionLink(replaceActionLink(location.href, linkParam));  // set the link to the document which contains a bookmark
        };

        // the meta information of the document is changed via the meta command
        var onMetaChange = function (event) {
            if (event.data.favorite) {
                var favorite = !!event.data.favorite;
                var title = document.title.replace(/^\☆/g, "");
                document.title = (favorite ? "☆" : "") + title;
                docEditor.setFavorite(favorite);  // change the Favorite icon state
            }

            innerAlert("onMetaChange: " + JSON.stringify(event.data));
        };

        // the user is trying to insert an image by clicking the Image from Storage button
        var onRequestInsertImage = function (event) {
            <% string logoUrl;%>
            <% Model.GetLogoConfig(out logoUrl); %>
            docEditor.insertImage({  // insert an image into the file
                "c": event.data.c,
                <%= logoUrl%>
            })
        };

        // the user is trying to select document for comparing by clicking the Document from Storage button
        var onRequestSelectDocument = function (event) {
            <% string documentData; %>
            <% Model.GetDocumentData(out documentData); %>
            var data = <%=documentData%>;
            data.c = event.data.c;
            docEditor.setRequestedDocument(data);  // select a document for comparing
        };

        // the user is trying to select recipients data by clicking the Mail merge button
        var onRequestSelectSpreadsheet = function (event) {
            <% string dataSpreadsheet; %>
            <% Model.GetSpreadsheetConfig(out dataSpreadsheet); %>
            var data = <%= dataSpreadsheet%>;
            data.c = event.data.c;
            docEditor.setRequestedSpreadsheet(data);  // insert recipient data for mail merge into the file
        };

         var onRequestSaveAs = function (event) {  //  the user is trying to save file by clicking Save Copy as... button
             var title = event.data.title;
             var url = event.data.url;
             var data = {
                 title: title,
                 url: url
             };
             let xhr = new XMLHttpRequest();
             xhr.open("POST", "webeditor.ashx?type=saveas");
             xhr.setRequestHeader('Content-Type', 'application/json');
             xhr.send(JSON.stringify(data));
             xhr.onload = function () {
                 innerAlert(xhr.responseText);
                 innerAlert(JSON.parse(xhr.responseText).file, true);
             }
         };

         var onRequestRename = function(event) { //  the user is trying to rename file by clicking Rename... button
            innerAlert("onRequestRename: " + JSON.stringify(event.data));

            var newfilename = event.data;
            var data = {
                newfilename: newfilename,
                dockey: config.document.key,
                ext: config.document.fileType
            };

            let xhr = new XMLHttpRequest();
            xhr.open("POST", "webeditor.ashx?type=rename");
            xhr.setRequestHeader('Content-Type', 'application/json');
            xhr.send(JSON.stringify(data));
            xhr.onload = function () {
                innerAlert(xhr.responseText);
            }
        };

        var onRequestOpen = function (event) {  // user open external data source
            innerAlert("onRequestOpen");
            var windowName = event.data.windowName;
            requestReference(event.data, function (data) {
                if (data.error) {
                    var winEditor = window.open("", windowName);
                    winEditor.close();
                    innerAlert(data.error, true);
                    return;
                }
                var link = data.link;
                window.open(link, windowName);
            });
        };

        var onRequestReferenceData = function (event) {  // user refresh external data source
            innerAlert("onRequestReferenceData");

            requestReference(event.data, function (data) {
                docEditor.setReferenceData(data);
            });
        };

        var requestReference = function (data, callback) {
            innerAlert(data);
            data.directUrl = !!config.document.directUrl;
            let xhr = new XMLHttpRequest();
            xhr.open("POST", "webeditor.ashx?type=reference");
            xhr.setRequestHeader("Content-Type", "application/json");
            xhr.send(JSON.stringify(data));
            xhr.onload = function () {
                console.log(xhr.responseText);
                callback(JSON.parse(xhr.responseText));
            }
        };

        var onRequestHistory = function () {
            let xhr = new XMLHttpRequest();
            xhr.open("GET", "webeditor.ashx?type=gethistory&filename=<%= Model.FileName %>");
            xhr.setRequestHeader("Content-Type", "application/json");
            xhr.send();
            xhr.onload = function () {
                console.log(xhr.responseText);
                docEditor.refreshHistory(JSON.parse(xhr.responseText));
            }
        };

        var onRequestHistoryData = function (event) {
            var ver = event.data;

            let xhr = new XMLHttpRequest();
            xhr.open("GET", "webeditor.ashx?type=getversiondata&filename=<%= Model.FileName %>&version=" + ver + "&directUrl=" + !!config.document.directUrl);
            xhr.setRequestHeader("Content-Type", "application/json");
            xhr.send();
            xhr.onload = function () {
                console.log(xhr.responseText);
                docEditor.setHistoryData(JSON.parse(xhr.responseText));  // send the link to the document for viewing the version history
            }
        };

        var onRequestRestore = function (event) {
            var fileName = "<%= Model.FileName %>";
            var version = event.data.version;
            var data = {
                fileName: fileName,
                version: version
            };

            let xhr = new XMLHttpRequest();
            xhr.open("POST", "webeditor.ashx?type=restore&directUrl=" + !!config.document.directUrl);
            xhr.setRequestHeader('Content-Type', 'application/json');
            xhr.send(JSON.stringify(data));
            xhr.onload = function () {
                docEditor.refreshHistory(JSON.parse(xhr.responseText));
            }
        }

        

        config = <%= Model.GetDocConfig(Request, Url) %>;

        config.width = "100%";
        config.height = "100%";

        config.events = {
            'onAppReady': onAppReady,
            'onDocumentStateChange': onDocumentStateChange,
            'onError': onError,
            'onOutdatedVersion': onOutdatedVersion,
            "onMakeActionLink": onMakeActionLink,
            "onMetaChange": onMetaChange,
            "onRequestInsertImage": onRequestInsertImage,
            "onRequestSelectDocument": onRequestSelectDocument,
            "onRequestSelectSpreadsheet": onRequestSelectSpreadsheet,
            'onSubmit': onSubmit,
            "onDocumentReady": onDocumentReady
        };

        <% string usersForMentions; %>
        <% Model.GetUsersMentions(Request, out usersForMentions); %>
        <% string usersInfo; %>
        <% Model.GetUsersInfo(Request, out usersInfo); %>
        <% string usersForProtect; %>
        <% Model.GetUsersProtect(Request, out usersForProtect); %>

        if (config.editorConfig.user.id) {
            // the user is trying to show the document version history
            config.events['onRequestHistory'] = onRequestHistory;
            // the user is trying to click the specific document version in the document version history
            config.events['onRequestHistoryData'] = onRequestHistoryData;
            // the user is trying to go back to the document from viewing the document version history
            config.events['onRequestHistoryClose'] = function () {
                document.location.reload();
            };
            config.events['onRequestRestore'] = onRequestRestore;

            // add mentions for not anonymous users
            <% if (!string.IsNullOrEmpty(usersForMentions))
            { %>
                config.events['onRequestUsers'] = function (event) {
                    if (event && event.data){
                        var c = event.data.c;
                    }
                    switch (c) {
                        case "info":
                            users = [];
                            var allUsers = <%= usersInfo %>;
                            for (var i = 0; i < event.data.id.length; i++) {
                                for (var j = 0; j < allUsers.length; j++) {
                                    if (allUsers[j].id == event.data.id[i]) {
                                        users.push(allUsers[j]);
                                        break;
                                    }
                                }
                            }
                            break;
                        case "protect":
                            var users = <%= usersForProtect %>;
                            break;
                        default:
                            users = <%= usersForMentions %>;
                    }
                    docEditor.setUsers({
                        "c": c,
                        "users": users,
                    });
                };
            <% } %>

            // the user is mentioned in a comment
            config.events['onRequestSendNotify'] = function (event) {
                event.data.actionLink = replaceActionLink(location.href, JSON.stringify(event.data.actionLink));
                var data = JSON.stringify(event.data);
                innerAlert("onRequestSendNotify: " + data);
            };
            // prevent file renaming for anonymous users
            config.events['onRequestRename'] = onRequestRename;
            config.events['onRequestReferenceData'] = onRequestReferenceData;
            // prevent switch the document from the viewing into the editing mode for anonymous users
            config.events['onRequestEditRights'] = onRequestEditRights;
            config.events['onRequestOpen'] = onRequestOpen;
            config.events['onSubmit'] = onSubmit;
        }

        if (config.editorConfig.createUrl) {
            config.events.onRequestSaveAs = onRequestSaveAs;
        };

        var сonnectEditor = function () {
            if ((config.document.fileType === "docxf" || config.document.fileType === "oform")
                && DocsAPI.DocEditor.version().split(".")[0] < 7) {
                innerAlert("Please update ONLYOFFICE Docs to version 7.0 to work on fillable forms online.");
                return;
            }

            docEditor = new DocsAPI.DocEditor("iframeEditor", config);
        };

        if (window.addEventListener) {
            window.addEventListener("load", сonnectEditor);
        } else if (window.attachEvent) {
            window.attachEvent("load", сonnectEditor);
        }

    </script>
</body>
</html>
