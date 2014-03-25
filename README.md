# TCL Markup Language

This package is able to parse `.tml` files, merge them with a context of variable values and output the resulting value into a string. This is useful in a large number of scenario's:

* rendering an HTML page with dynamic content
* generating e-mail templates
* .. etc

The syntax is very simple and might remind you of other templating tools such as JSPs and PHP.

#### Render a file

To render a file, using the following:

    Tml::render "yourfile.tml" {
        pageTitle "Your page title"
        links $links
    } 

This will grab `yourfile.tml` (shown below) and merge the file with the information in the context array.

One can integrate TCL command simply by wrapping them with `<% ... %>`. Instead of using a `{` to start the body of an element TML needs you to end it with a colon, this indicates the start of a new scope. Ending the code block is done by the `<% end %>` statement. 

    <!doctype html>
    <html>
        <head>
            <title><%= $pageTitle %></title>

            <%= [render "views/_include_me.tml"] %>
        </head>

        <body>

            <ul>
                <% foreach link $links: %>
                    <li><a href="<%= [link.url link] %>"><%= [link.label link] %></a></li>
                <% end %>
            </ul>

        </body>
    </html>

Because TML rendering is executed inside the `Tml` namespace, including another template is easy, just invoke `render` again. 

Multi-line code is not supported, partly because of the naive nature of the parser that was built, but also as a reminder that, if you ever need that, you're doing it wrong. The view model should be completely built when rendering starts. 

Outputting a variable is done using the `<%= .. %>`-notation. 