# Нотация ajax ответа от сервера

## Формат ответа
Мы работаем с *json*, формат ответа должен быть единый для всех ответов. 
В работе мы не используем *DOM* мы передаем *HTML* код, который потом вставляем в контейнер (DOM-элемент)

```js
$response = array('status' => 'error' | 'ok',
                  'status_extended' => string, // дополнительное обозначение статуса, notice, warning или что-то еще
                  'data'    => mixed
                  'reload' => boolean // нужно сделать перезагрузку текущей страницы
                  'redirect' => 'url' // страница куда нужно сделать редирект
                  'message' => '' // cтрока с первой ошибкой из messages
                  'messages' => array(
                      array('code' => mixed, // если нет, то general
                            'field' => mixed // если нет, то general
                            'message' => string))
                 );
```

ЗАПРЕЩЕНО ПОЛЬЗОВАТЬСЯ **$.ajax** НУЖНО ИСПОЛЬЗОВАТЬ ФУНКЦИЮ **ajaxJson**

*Правильный пример:*

```js
ajaxJson('http://test.domain.com/privet/mir/?test=1', {'do' : 'edit'}, 
function (response) { // Что делаем при получении данных
    /**
     * response.status   - может быть только ok или error
     * response.data     - данные
     * response.reload   - нужно ли перезагружать страницу // обрабатывается в ajaxJson 
     * response.redirect - куда перенаправить пользователя // обрабатывается в ajaxJson
     * response.message  - первое сообщение из messages
     * response.messages - много сообщений
     */
 
}, 
'POST', 
function(message) { // Что делаем при ошибках
 
}, 
10000 // timeout 1000 - 1sec
);

```

## Формат URL для Ajax-запросов

Абсолютно все *Url* Ajax-запросов должны начинаться с **/ajax/**<br/>
Соответственно все *Action* которые не используют context switch должны начинаться с ajax.<br/>
*Ajax-action*'s в конроллере должны располагаться в конце файла.
