package rt.pipeline

import com.google.gson.Gson
import com.google.gson.JsonDeserializer
import rt.pipeline.IMessageBus.Message
import java.util.LinkedList
import java.util.List
import com.google.gson.GsonBuilder
import java.util.ArrayList

class DefaultMessageConverter {
	val (List<String>, Class<?>[]) => List<Object> argsConverter = [ values, types |
		if (types.length != values.size)
			throw new RuntimeException('Invalid number of arguments!')
		
		val args = new ArrayList<Object>(types.length)
		
		val valuesIter = values.iterator
		for (type: types)
			args.add(gson.fromJson(valuesIter.next, type))
		
		return args
	]
	
	val (String, Class<?>) => Object resultConverter = [ value, type |
		return gson.fromJson(value, type)
	]
	
	val JsonDeserializer<Message> deserializer = [ json, typeOfT, ctx |
		val obj = json.asJsonObject
		
		val jsonArgs = new LinkedList<String>
		val jsonResult = obj.get('res')?.toString
		
		val args = obj.get('args')?.asJsonArray
		args?.forEach[
			jsonArgs.add(toString)
		]
		
		return new Message(jsonArgs, argsConverter, jsonResult, resultConverter) => [
			id = obj.get('id').asLong
			cmd = obj.get('cmd')?.asString
			clt = obj.get('clt')?.asString
			path = obj.get('path')?.asString
			error = obj.get('error')?.asString
		]
	]
	
	val gsonBuilder = new GsonBuilder => [
		registerTypeAdapter(Message, deserializer)
	]

	val Gson gson = gsonBuilder.create
	
	def String toJson(Message msg) {
		return gson.toJson(msg)
	}
	
	def Message fromJson(String json) {
		return gson.fromJson(json, Message)
	}
}