class BootStrap {
   
     def init = { servletContext ->
         Thread.start {
             println "forked sync index thread"
             WorkMetadata.syncIndex()
             Item.syncIndex()
             println "bulk sync thread finished"
             def wmSearchCount = WorkMetadata.countHits('*:*')
             if(wmSearchCount == 0) {
                 println "WorkMetadata index needs to be recreated, starting full index"
                 WorkMetadata.index()
                 println "WorkMetadata full index complete"                 
             }
             def iSearchCount = Item.countHits('*:*')
             if(iSearchCount == 0) {
                 println "Item index needs to be recreated, starting full index"
                 Item.index()
                 println "Item full index complete"                 
             }             
         }
     }
     def destroy = {
     }
} 