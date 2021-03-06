# Систетема блоков

## Что такое блок

Блок это часть шаблона, которую мы можем использовать повтовно в другом шаблоне. 
Блок имеет набор собственных параметров.

## Проблемы

* Есть необходимость в шаблонах с разными настройками;
* Нужно немного влиять на шаблон в зависимости от его использования;
* Мы заранее не знаем где может использоваться блок.

## Использование

Пользователь можем изменять шаблоны своего сайта из панели администрирования. При этом он может переставлять отдельные элементы как в пределах одного шаблона, так и переносить/добавлять в другие.

## Внутреннее устройство

### С чего начинается блок

Блок начинается с определения самого блока. У каждого блока есть:
* Имя (оно уникально);
* Тип (pseudo, real - default);
* Label - как он будет называться в админке;
* Позиция - каким он будет в очереди на обработку;
* Show - показывать/обрабатывать ли блок.

```xml
<block name="sidebar" type="real" label="Side bar" pos="1" show="true">
</block>
```

### Параметры блоков

Все параметры блоков разделяются на два вида:
* Обычные (тег param);
* Системные/контрольные.

Параметры всегда имеют одну и ту же сигнатуру:

```xml
<param name="param_name" type="string" label="Param label" pos="1" value="Param value" show="true" />
```

## Системные параметры блоков

### Parent - родитель (для наследования блоков)

```xml
<block>
    <!-- Родительский элемент от которого наследуем настройки -->
    <param name="param_name" type="string" label="Param label" pos="1" value="Param value" show="true" />
</block>
```

### inner_block - обернуть вложенные блоки в HTML tag

```xml
<inner_block>
    <param name="show" type="boolean" value="true"/>
    <param name="html_tag" type="string" value="span"/>
    <param name="css_class" type="string" value="css_class"/>
    <param name="modifier_css_class" type="string" value="modifier_css_class"/>
</inner_block>
```

### controller/action - управление блоком в контроллере

```xml
<block>
    <!-- Controller/Action для обработки -->
    <controller value="index" />
    <action value="index" />
</block>
```
