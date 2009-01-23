class UrlMappings {
    static mappings = {              
      "/$controller/search/explain"(action:"explain")
      "/$controller/search/"(action:"search")
      "/$controller/-/$filter/"(action:"filter")
      "/$controller/$id/$relationship"(action:"relationship")
      "/$controller/$id/$relationship/-/$filter"(action:"relationshipFilter")
      "/$controller/$id?"(action:"index")



      "/$controller/$action?/$id?"{
	      constraints {
			 // apply constraints here
		  }
	  }
	  "500"(view:'/error')
	}
}
