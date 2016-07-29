package rt.vertx.server.web.service

import java.util.List
import rt.data.Data
import rt.plugin.service.an.Public
import rt.plugin.service.an.Service
import rt.plugin.service.an.Proxy

@Service
@Data(metadata = false)
class TransferService {
	
	@Public
	def List<SrvPoint> srvPoints() {
		return null
	}
	
	@Public
	@Proxy(name = 'events', type = EventsProxy)
	def String srvPointObservable() {
		//TODO: get ObservableService and register
		//val rObserver = srvObservable.register
		//return rObserver.id
		
		return null
	}
	
	@Public
	def void transferPatients(List<String> patients, String srvPointId) {
	
	}
	
	@Public
	def List<PatientTransfer> patientTransfers(String srvPointId) {
		return null
	}
	
	@Public
	@Proxy(name = 'events', type = EventsProxy)
	def String patientTransferObservable(String srvPointId) {
		//TODO: get ObservableService and register
		//val rObserver = srvObservable.register
		//return rObserver.id
		
		return null
	}
}

@Data
class SrvPoint {
	val String id
	val String name
}

@Data
class PatientTransfer {
	val String id	//PatientID
	val int transferred
	val int errors
	val String lastErrorMessage
}