class CoreController {
    def coreService
    def retrieve = {
        def connector_response = coreService.getRequest(params.connector_name, params.path, params)
        return(render(view:connector_response.type, model:['jangle':connector_response]))
    }
}
