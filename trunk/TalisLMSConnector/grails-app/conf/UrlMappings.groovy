class UrlMappings {
    static mappings = {              
      "/connector/$controller/search/explain"(action:"explain")
      "/connector/$controller/search/"(action:"search")
      "/connector/$controller/-/$filter/"(action:"filter")
      "/connector/$controller/$id/$relationship"(action:"relationship")
      "/connector/$controller/$id/$relationship/-/$filter"(action:"relationshipFilter")
      "/connector/$controller/$id?"(action:"index")
      "/$connector_name/$path**"(controller:"core",action = [GET:"retrieve"]
)


      "/$controller/$action?/$id?"{
	      constraints {
			 // apply constraints here
		  }
	  }
	  "500"(view:'/error')
	}
}
