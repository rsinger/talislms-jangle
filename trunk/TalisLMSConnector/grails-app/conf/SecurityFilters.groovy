class SecurityFilters {
    def feedService
	def filters = {
			basicAuth(controller:'actors', action:'*') {
		           before = {
		            	 def authString = request.getHeader('Authorization')
		            	 if(!authString){
		            		 return
		            	 }

		            	 def encodedPair = authString - 'Basic '
		            	 def decodedPair =  new String(new sun.misc.BASE64Decoder().decodeBuffer(encodedPair));
		            	 def credentials = decodedPair.split(':')
                         if(!(credentials[0] && credentials[1])) {
                             return
                         }
                         if(feedService.config.adminAccounts[credentials[0]]) {                            
                             if(feedService.config.adminAccounts[credentials[0]] == credentials[1]) {
                                 session.user = credentials[0]
                                 session.user_level = 100
                             } else {
                                 return
                             }
                         } else {
                             def user = Borrower.findByBarcodeAndPin(credentials[0],credentials[1])

                             if(user){
                                 session.user = user.id
                                 session.user_level = 1
                             } else {
                                return
		            		 }

		            	 }
		           }
		     }
    }
}