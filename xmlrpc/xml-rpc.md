##Стандарт XmlRpc

###Формат возвращаемых данных

**Общая схема ответа**

<code>
    status => статус // Должен всегда присутствовать 
    status_extended => расширенный статус // Должен всегда присутствовать 
    message => сообщение об операции, например, «Все ОК», «Ты дебил, смотри какие ошибки допустил», «Тут что-то не так», etc... 
    data => данные 
    messages => сообщения, всегда массив!
</code>
	
**Статусы ответа**

<code>
    ok – все хорошо! 
    error – критическая ошибка, все плохо!
</code>
	
**Расширенные статусы**

<code>
    ok – все хорошо! 
	notice – Уведомление 
	warning – Внимание!
	error – критическая ошибка, все плохо!
</code>

Если массив messages содержит сообщения всех этих типов, или каких-то. То выбирается наиболее приоритетный. Приоритет идет снизу вверх, то есть если есть и notice и warning – общий расширенный статус будет warning

**Сообщения**

Массив двойной вложенности с ошибками, рассмотрим только один элемент этого массива

<code>
    status => см. выше, если не определена, то наследуется от общего статуса 
    code => Код ошибки/варнинга/прочего 
    field => Поле, если есть конечно 
    message => Текст сообщения
</code>
	
**Статусы сообщений**
<code>
    ok – все хорошо! 
    notice – уведомление, например, «Мы добавили, все ок, но это не совсем правильно» 
    warning – предупреждение, например, «Мы конечно добавили, но не все» 
    error – критическая ошибка, все плохо!
</code>

**Пример:**

<code>
    <?php 
        Array (
            [status] => error 
            [message] => Ошибочка вышла 
            [messages] => Array (
            [0] => Array (
	            [code] => 0 
		        [message] => Field 'email' is required by rule 'email', but the field is missing 
		        [field] => user.0__email 
		        ) 
    	    [1] => Array ( 
	            [status] => warning 
	        	[code] => 0 
    		    [message] => Field 'level' is required by rule 'level', but the field is missing 
		        [field] => user.1__ticket_comment.0__level 
	    	    ) 
        	[2] => Array ( 
	            [code] => 0 
    	    	[message] => Field 'ticket_id' is required by rule 'ticket_id', but the field is missing 
		        [field] => user.1__ticket_comment.0__ticket_id 
		        ) 
    	    [3] => Array ( 
	            [code] => 0 
		        [message] => Field 'comment' is required by rule 'comment', but the field is missing 
		        [field] => user.1__ticket_comment.0__comment 
	            ) 
	        ) 
        ) 
    ?>
</code>








