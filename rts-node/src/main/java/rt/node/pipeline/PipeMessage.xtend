package rt.node.pipeline

import io.vertx.core.json.JsonObject
import io.vertx.core.json.JsonArray

class PipeMessage {
	static val String ID = "id"
	static val String CMD = "cmd"
	static val String CLIENT = "client"
	static val String PATH = "path"
	
	static val String ARGS = "args"
	static val String RESULT = "result"
	
	public static val String OK = "ok"
	public static val String ERROR = "error"
	
	val JsonObject msg
	
	new() { this(new JsonObject) }
	new(String json) { this(new JsonObject(json)) }
	new(JsonObject msg) { this.msg = msg }
	
	def getJson() { return msg }
	
	def getId() { return msg.getLong(ID) }
	def void setId(long id) { msg.put(ID, id) }
	
	def getCmd() { return msg.getString(CMD) }
	def void setCmd(String type) { msg.put(CMD, type) }
	
	def getClient() { return msg.getString(CLIENT) }
	def void setClient(String client) { msg.put(CLIENT, client) }
	
	def getPath() { return msg.getString(PATH) }
	def void setPath(String path) { msg.put(PATH, path) }
	
	def getArgs() { return msg.getJsonArray(ARGS) }
	def void setArgs(JsonArray args) { msg.put(ARGS, args) }
	
	def getError() { return msg.getString(ERROR) }
	def void setError(String error) {
		cmd = ERROR
		msg.put(ERROR, error)
	}
	
	def getResult() { return msg.getJsonObject(RESULT) }
	def void setResult(JsonObject result) {
		cmd = OK
		msg.put(RESULT, result)
	}
	
	override toString() { return msg.toString }
}