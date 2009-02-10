<%@ page contentType="application/atom+xml;charset=UTF-8" %>
<feed xmlns="http://www.w3.org/2005/Atom" xmlns:jangle="http://jangle.org/vocab/">
  <title>${jangle.title}</title>
  <id>${request.forwardURI}</id>
  <updated>${jangle.time}</updated>
  <g:each var="alt" in="${jangle.alternate_formats.keySet().toList()}">
    <link rel="${alt}" href="${jangle.alternate_formats[alt]}" />
  </g:each>
  <g:each var="entry" in="${jangle.data}">
    <entry>
      <id>${entry.id}</id>
      <link href="${entry.id}" jangle:format="${entry.format}"/>
      <g:each var="alt" in="${entry.alternate_formats.keySet().toList()}">
        <link rel="${alt}" href="${entry.alternate_formats[alt]}" type="application/atom+xml" />
      </g:each>
      <g:each var="relationship" in="${entry.relationships.keySet().toList()}">
        <link rel="related" href="${entry.relationships[relationship]}" type="application/atom+xml" jangle:relationship="${relationship}" />
      </g:each>
      <title>${entry.title}</title>
      <g:if test="${entry.author}"><author><name>${entry.author}</name></author></g:if>
      <g:if test="${entry.description}"><summary>${entry.description}</summary></g:if>
      <g:if test="${entry.content}">
        <content type="${entry.content_type}">
${entry.content}
        </content>
      </g:if>
      <g:if test="${entry.categories}">
        <g:each in="${entry.categories}"><category term="${it}" /></g:each>
      </g:if>
    </entry>
  </g:each>
</feed>
