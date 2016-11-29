package rt.pipeline.bus

import com.google.gson.Gson
import com.google.gson.GsonBuilder
import com.google.gson.JsonDeserializer
import java.util.ArrayList
import java.util.LinkedList
import java.util.List
import java.util.Map

class DefaultMessageConverter {
	val JsonDeserializer<Message> deserializer = [ json, typeOfT, ctx |
		val obj = json.asJsonObject
		
		val jsonArgs = new LinkedList<Object>
		val jsonResult = obj.get('res')?.toString
		
		val objArgs = obj.get('args')?.asJsonArray
		objArgs?.forEach[ jsonArgs.add(toString) ]
		
		val jsonHeaders = obj.get('headers')?.asJsonObject
		
		return new Message(jsonArgs.createArgsConverter, jsonResult.createResultConverter) => [
			id = obj.get('id').asLong
			typ = obj.get('typ')?.asString
			cmd = obj.get('cmd')?.asString
			clt = obj.get('clt')?.asString
			path = obj.get('path')?.asString
			
			if (jsonHeaders != null)
				headers = gson.fromJson(jsonHeaders, Map)
		]
	]
	
	val gsonBuilder = new GsonBuilder => [
		registerTypeAdapter(Message, deserializer)
	]

	val Gson gson = gsonBuilder.create
	
	def createArgsConverter(List<Object> jsonArgs) {
		val (Class<?>[]) => List<Object> converter = [ types |
			if (types.length != jsonArgs.size)
				throw new RuntimeException('Invalid number of arguments!')
			
			val args = new ArrayList<Object>(types.length)
			
			val valuesIter = jsonArgs.iterator
			for (type: types) {
				val next = valuesIter.next
				if (next === null)
					throw new RuntimeException("Argument map non existent!")
				
				if (next.class == String) {
					args.add(gson.fromJson(next as String, type))
				} else {
					args.add(next)
				}
			}
			
			return args
		]
		
		return converter
	}
	
	def createResultConverter(String jsonResult) {
		val (Class<?>) => Object converter = [ type |
			return gson.fromJson(jsonResult, type)
		]
		
		return converter
	}
	
	def String toJson(Object obj) {
		return gson.toJson(obj)
	}
	
	def String toJson(Message msg) {
		return gson.toJson(msg)
	}
	
	def Message fromJson(String json) {
		return gson.fromJson(json, Message)
	}
}