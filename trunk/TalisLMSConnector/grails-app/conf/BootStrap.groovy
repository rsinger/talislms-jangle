class BootStrap {
    def exceptionHandler
     def init = { servletContext ->
        exceptionHandler.exceptionMappings =
            [ 'ConnectorClientException' :'/core/renderHttpError',
              'java.lang.Exception' : '/error']

     }
     def destroy = {
     }
} 