

    --
    -- Структура таблицы `product`
    --

    CREATE TABLE IF NOT EXISTS `product` (
      `id` int(11) unsigned NOT NULL AUTO_INCREMENT,
      `name` varchar(256) NOT NULL COMMENT 'Имя',
      `price` double(9,2) DEFAULT NULL COMMENT 'Цена',
      `primary_image_id` int(11) unsigned DEFAULT NULL COMMENT 'Главное изображение товара',
      `primary_rubric_id` int(11) unsigned DEFAULT NULL COMMENT 'ID основной рубрики',
      `slug` varchar(128) NOT NULL COMMENT 'Slug',
      `path` varchar(1024) DEFAULT NULL COMMENT 'Путь до карточки продукта',
      `path_hash` varchar(40) DEFAULT NULL COMMENT 'Хэш пути',
      `status` enum('active','inactive','unavailable') NOT NULL DEFAULT 'active' COMMENT 'статус продукта',
      `modify_date` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
      `create_date` timestamp NULL DEFAULT NULL,
      PRIMARY KEY (`id`),
      UNIQUE KEY `primary_rubric_id_2` (`primary_rubric_id`,`slug`),
      UNIQUE KEY `path_hash` (`path_hash`),
      KEY `primary_image_id` (`primary_image_id`),
      KEY `primary_rubric_id` (`primary_rubric_id`)
    ) ENGINE=InnoDB  DEFAULT CHARSET=utf8 COMMENT='Таблица продуктов' AUTO_INCREMENT=151 ;

    -- --------------------------------------------------------

    --
    -- Структура таблицы `product_image`
    --

    CREATE TABLE IF NOT EXISTS `product_image` (
      `id` int(11) unsigned NOT NULL AUTO_INCREMENT,
      `product_id` int(11) unsigned NOT NULL COMMENT 'ID товара',
      `filename` varchar(256) DEFAULT NULL COMMENT 'Имя файла',
      `fileextension` char(12) DEFAULT NULL COMMENT 'Расширение файла',
      `filepath` char(5) DEFAULT NULL COMMENT 'Путь к файлу',
      `filehash` varchar(40) DEFAULT NULL COMMENT 'Хэш файла',
      `filesize` int(11) unsigned DEFAULT NULL COMMENT 'Размер файла',
      `create_date` timestamp NULL DEFAULT NULL COMMENT 'Дата создания',
      `modify_date` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT 'Дата изменения',
      PRIMARY KEY (`id`),
      UNIQUE KEY `product_id_2` (`product_id`,`filehash`),
      KEY `product_id` (`product_id`)
    ) ENGINE=InnoDB  DEFAULT CHARSET=utf8 AUTO_INCREMENT=560 ;

    -- --------------------------------------------------------

    --
    -- Структура таблицы `product_info`
    --

    CREATE TABLE IF NOT EXISTS `product_info` (
      `id` int(11) unsigned NOT NULL AUTO_INCREMENT,
      `product_id` int(11) unsigned NOT NULL COMMENT 'ID товара',
      `description` longtext COMMENT 'Описание товара',
      PRIMARY KEY (`id`),
      UNIQUE KEY `product_id` (`product_id`)
    ) ENGINE=InnoDB  DEFAULT CHARSET=utf8 AUTO_INCREMENT=148 ;

    -- --------------------------------------------------------

    --
    -- Структура таблицы `product_rubric_link`
    --

    CREATE TABLE IF NOT EXISTS `product_rubric_link` (
      `product_id` int(11) unsigned NOT NULL COMMENT 'ID товара',
      `rubric_id` int(11) unsigned NOT NULL COMMENT 'ID рубрики',
      PRIMARY KEY (`product_id`,`rubric_id`),
      KEY `product_id` (`product_id`,`rubric_id`),
      KEY `rubric_id` (`rubric_id`)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8;

    -- --------------------------------------------------------

    --
    -- Структура таблицы `rubric`
    --

    CREATE TABLE IF NOT EXISTS `rubric` (
      `id` int(11) unsigned NOT NULL AUTO_INCREMENT COMMENT 'ID рубрики',
      `parent_id` int(11) unsigned DEFAULT NULL COMMENT 'ID родителя',
      `level` tinyint(3) unsigned NOT NULL DEFAULT '1' COMMENT 'Уровень в дереве',
      `pos` double DEFAULT NULL COMMENT 'Позиция в списке',
      `status` enum('active','unavailable','inactive') NOT NULL DEFAULT 'active' COMMENT 'Статус (active - активная рубрика, unavailable - неактивная, но можно восстановить в админке, inactive - удалена)',
      `name` varchar(128) NOT NULL COMMENT 'Навзание рубрики',
      `slug` varchar(128) NOT NULL COMMENT 'Slug',
      `path` varchar(1024) DEFAULT NULL COMMENT 'Путь к рубрике',
      `path_hash` varchar(40) DEFAULT NULL COMMENT 'Хэш пути',
      `create_date` timestamp NULL DEFAULT NULL COMMENT 'Дата создания',
      `modify_date` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT 'Дата изменения',
      PRIMARY KEY (`id`),
      UNIQUE KEY `path_hash` (`path_hash`),
      UNIQUE KEY `parent_id_2` (`parent_id`,`slug`),
      KEY `parent_id` (`parent_id`),
      KEY `level` (`level`),
      KEY `pos` (`pos`)
    ) ENGINE=InnoDB  DEFAULT CHARSET=utf8 COMMENT='Рубрики' AUTO_INCREMENT=300 ;

    --
    -- Триггеры `rubric`
    --
    DROP TRIGGER IF EXISTS `trg_bi_rubric`;
    DELIMITER //
    CREATE TRIGGER `trg_bi_rubric` BEFORE INSERT ON `rubric`
     FOR EACH ROW BEGIN
        IF NEW.parent_id = 0 THEN
            SET NEW.parent_id = NULL;
        END IF;

        IF NEW.parent_id IS NOT NULL THEN
            SET @parent_level := (SELECT `level` FROM rubric WHERE id = NEW.parent_id);
            SET NEW.level = @parent_level + 1;
        ELSE
            SET NEW.level = 1;
        END IF;

        IF NEW.pos IS NULL THEN
            SET @pos := (SELECT FLOOR(`pos`) FROM rubric WHERE pos IS NOT NULL ORDER BY pos LIMIT 1);
            SET NEW.pos = @pos - 32;
        END IF;
    END
    //
    DELIMITER ;
    DROP TRIGGER IF EXISTS `trg_bu_rubric`;
    DELIMITER //
    CREATE TRIGGER `trg_bu_rubric` BEFORE UPDATE ON `rubric`
     FOR EACH ROW BEGIN

        IF NEW.parent_id = 0 THEN
            SET NEW.parent_id = NULL;
        END IF;

        IF NEW.parent_id IS NOT NULL THEN
            SET @parent_level := (SELECT `level` FROM rubric WHERE id = NEW.parent_id);
            SET NEW.level = @parent_level + 1;
        ELSE
            SET NEW.level = 1;
        END IF;
    END
    //
    DELIMITER ;

    --
    -- Ограничения внешнего ключа сохраненных таблиц
    --

    --
    -- Ограничения внешнего ключа таблицы `product`
    --
    ALTER TABLE `product`
      ADD CONSTRAINT `product_ibfk_1` FOREIGN KEY (`primary_image_id`) REFERENCES `product_image` (`id`) ON DELETE SET NULL ON UPDATE SET NULL,
      ADD CONSTRAINT `product_ibfk_2` FOREIGN KEY (`primary_rubric_id`) REFERENCES `rubric` (`id`) ON DELETE SET NULL ON UPDATE SET NULL;

    --
    -- Ограничения внешнего ключа таблицы `product_image`
    --
    ALTER TABLE `product_image`
      ADD CONSTRAINT `product_image_ibfk_1` FOREIGN KEY (`product_id`) REFERENCES `product` (`id`) ON DELETE CASCADE ON UPDATE CASCADE;

    --
    -- Ограничения внешнего ключа таблицы `product_info`
    --
    ALTER TABLE `product_info`
      ADD CONSTRAINT `product_info_ibfk_1` FOREIGN KEY (`product_id`) REFERENCES `product` (`id`) ON DELETE CASCADE ON UPDATE CASCADE;

    --
    -- Ограничения внешнего ключа таблицы `product_rubric_link`
    --
    ALTER TABLE `product_rubric_link`
      ADD CONSTRAINT `product_rubric_link_ibfk_1` FOREIGN KEY (`product_id`) REFERENCES `product` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
      ADD CONSTRAINT `product_rubric_link_ibfk_2` FOREIGN KEY (`rubric_id`) REFERENCES `rubric` (`id`) ON DELETE CASCADE ON UPDATE CASCADE;

    --
    -- Ограничения внешнего ключа таблицы `rubric`
    --
    ALTER TABLE `rubric`
      ADD CONSTRAINT `rubric_ibfk_1` FOREIGN KEY (`parent_id`) REFERENCES `rubric` (`id`) ON DELETE CASCADE ON UPDATE CASCADE;
