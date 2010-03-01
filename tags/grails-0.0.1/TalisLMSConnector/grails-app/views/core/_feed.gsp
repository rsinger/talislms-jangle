<%@ page contentType="application/atom+xml;charset=UTF-8" %>
<feed xmlns="http://www.w3.org/2005/Atom" xmlns:jangle="http://jangle.org/vocab/">
  <title><jfeed:esc>${jangle.title}</jfeed:esc></title>
  <id>${request.forwardURI}</id>
  <updated>${jangle.time}</updated>
  <g:each var="alt" in="${jangle.alternate_formats.keySet().toList()}">
    <link rel="${alt}" href="${jangle.alternate_formats[alt]}" />
  </g:each>
  <jfeed:pagelink rel="first" uri="${request.forwardURI}" />
  <g:if test="${jangle.offset > 0}">    
    <g:if test="${((jangle.offset - jangle.data.size()) > 0)}">
      <g:set var="offset" value="${(jangle.offset - jangle.data.size())}" />
    </g:if>
    <g:else><g:set var="offset" value="0"/></g:else>
    <jfeed:pagelink rel="previous" uri="${request.forwardURI}" offset="${offset}" />
  </g:if>
  <g:if test="${((jangle.totalResults - jangle.data.size()) > jangle.offset)}">
    <jfeed:pagelink rel="next" uri="${request.forwardURI}" offset="${jangle.offset+jangle.data.size()}" />
  </g:if>
  <g:if test="${jangle.totalResults/jangle.data.size() == 1}">
    <jfeed:pagelink rel="last" uri="${request.forwardURI}" />
  </g:if>
  <g:else>
    <jfeed:pagelink rel="last" uri="${request.forwardURI}" offset="${((jangle.totalResults/jangle.data.size()).toInteger())*jangle.data.size()}"/>
  </g:else>
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
      <title><jfeed:esc>${entry.title}</jfeed:esc></title>
      <g:if test="${entry.author}"><author><name><jfeed:esc>${entry.author}</jfeed:esc></name></author></g:if>
      <g:if test="${entry.description}"><summary><jfeed:esc>${entry.description}</jfeed:esc></summary></g:if>
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
