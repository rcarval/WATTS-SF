/**********************************************************************************
Desarrollado por: Seidor
Autor: (Brayan Baquero - BB)
Proyecto: Watts
Descripción: Clase encolable que llama clase Batch EffectiveAccountManagerSyncBatch
---------------------------------------------------------------------------------
No. Fecha                Autor                     Descripción
------ ---------- ---------------------------------------------------------------
1.0 05-01-2026           BB                     Creación de la Clase.    
***********************************************************************************/
public class SEIDOR_EjecutaBatchAccManOrgUnitQueue implements Queueable {
    public String idRegistroBatch{get;set;}

    public void execute(QueueableContext qc){
        
        AsyncApexJob apexJob = [SELECT Id, Status, ApexClass.Name, JobType, 
                                CronTriggerId, LastProcessed, CompletedDate, 
                                CreatedDate, createdBy.Name 
                                FROM AsyncApexJob WHERE Id =: idRegistroBatch];
        Configuracion_Batch_Size__mdt datosBatchSize = new Configuracion_Batch_Size__mdt();
        datosBatchSize = Configuracion_Batch_Size__mdt.getInstance('BatchSize');
        Integer batchSize = 5;
        if(datosBatchSize != null){
            batchSize = Integer.valueOf(datosBatchSize.Batch_Size__c);
        }
        
        //Si Proceso Batch está finalizado llama a segundo método, de lo contrario, vuelve a encolar misma clase para
        //ejecución de Batch EffectiveAccountManagerSync
        if(apexJob.Status == 'Completed'){
            cgcloud.EffectiveAccountManagerSyncBatch effAccMgrbatch = new cgcloud.EffectiveAccountManagerSyncBatch();
            Id effAccMgrbatchJobId = Database.executeBatch(effAccMgrbatch, batchSize);//NOPMD
            
        }else{
            SEIDOR_EjecutaBatchAccManOrgUnitQueue claseEncolable = new SEIDOR_EjecutaBatchAccManOrgUnitQueue();
            claseEncolable.idRegistroBatch = idRegistroBatch;
            //Debido a que hay una dependencia entre clases y meten en memoria la Id de la cola y clase
            //NO se vuelve a llamar a encolar la misma clase para no generar una excepción
            if(!Test.IsRunningTest()){
                System.enqueueJob(claseEncolable,1);
            }else{
                //Ejecución solo para test
                cgcloud.EffectiveAccountManagerSyncBatch effAccMgrbatch = new cgcloud.EffectiveAccountManagerSyncBatch();
                Id effAccMgrbatchJobId = Database.executeBatch(effAccMgrbatch, batchSize);//NOPMD
            }
        }
    }
}