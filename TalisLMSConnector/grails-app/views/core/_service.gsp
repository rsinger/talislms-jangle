<%@ page contentType="application/atomsvc+xml;charset=UTF-8" %>
<service xmlns="http://www.w3.org/2007/app" xmlns:atom="http://www.w3.org/2005/Atom">
  <g:each var="connector" in="${jangle.keySet().toList()}"><workspace>
      <atom:title><jfeed:esc>${jangle[connector].title}</jfeed:esc></atom:title>
      <g:each var="entity" in="${jangle[connector].entities.keySet().toList()}">
        <collection href="${jangle[connector].entities[entity]['uri']}">
          <atom:title><g:if test="${jangle[connector].entities[entity].title}">
<jfeed:esc>${jangle[connector].entities[entity].title}</jfeed:esc></g:if>
<g:else><jfeed:esc>${entity}</jfeed:esc></g:else></atom:title>
        <g:if test="${jangle[connector].entities[entity].categories}">
          <g:each var="cat" in="${jangle[connector].entities[entity].categories}">
            <jfeed:categoryBuilder category="${cat}" categories="${jangle[connector].categories}" />
          </g:each>
        </g:if>
        </collection></g:each>
    </workspace></g:each>
</service>

