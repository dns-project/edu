#Models

Рассмотрим подробнее, что умеют модели. 
Рассматривать будем на примере урезанного интернет-магазина. Допустим у нас есть таблицы -
- product - таблица продуктов, 
- product_info - описание каждого продукта вынесено в отдельную таблицу, связь один-к-одному
- product_image - картиночки продуктов, связь один-ко-многим
- rubric - рубрики нашего магазина,
- product_rubric_link - связь многие-ко-многим наших рубрик с товарами.     

Примерные sql-нички для создания этих табличек с проставлленными индексами, связями и триггерами можно глянуть здесь 
https://github.com/esteit/edu/blob/master/models/test_db.sql


##Singleton. Объект модели

Начнем с того, что модель использует паттерн проектирования Singleton http://ru.wikipedia.org/wiki/%D0%9E%D0%B4%D0%B8%D0%BD%D0%BE%D1%87%D0%BA%D0%B0_(%D1%88%D0%B0%D0%B1%D0%BB%D0%BE%D0%BD_%D0%BF%D1%80%D0%BE%D0%B5%D0%BA%D1%82%D0%B8%D1%80%D0%BE%D0%B2%D0%B0%D0%BD%D0%B8%D1%8F)

Это означает, что объект модели всегда один. 
Получить объект модели можно с помощью статического метода getInstance()

    $productModel1 = ProductModel::getInstance();
    $productModel2 = ProductModel::getInstance();
    
Первый раз при вызове ProductModel::getInstance() будет создан объект модели ProductModel. При втором вызове будет возвращен этот же объект. Соответственно $productModel1 и $productModel2 это ссылки на один и тот же объект. 

##Выборки
В сгенерированной модельке для таблицы продуктов ProductModelAbstract находятся методы для выбора продукта/ов из бд. Рассмотрим некоторые из них. 
 
    /**
     * Получить одну запись 'Product'
     *
     * @param Model_Cond $opts Объект опций - Дядя Кондиций :)
     * @return ProductEntity Запись 'Product'
     */
    public function getProduct(Model_Cond $opts = null)
    {
        return $this->_getProduct($opts);
    }
    
Это метод для получения одного продукта из бд. Все выборки моделей принимают параметр Model_Cond $opts Объект опций - Дядя Кондиций. Это опции выборки. Рассмортим их

##Кондиции
Model_Cond это такой объект с помощью которого вы можете передавать какие-то опции выборке (знаю,чем больше самоубийц - тем меньше самоубийц). Т.е практически все операторы, которые вы задаете в обычном sql типа where, group, having, join, limit, offset, order, distinct задаются в объекте кондиций. Здесь же можно указать, например columns - т.е. это те столбцы, которые нужно выбирать (по умолчанию *).

Давайте посмотрим несколько примеров sql запросов и их аналогов для моделей.

    $productModel = ProductModel::getInstance();
    
    $sql = 'select * from product';    
    $productList = $productModel->getProductList();
        

Таким образом мы получили весь список продуктов в виде ProductCollection. В данном примере мы не использовали объект кондиций (будеи называть их "опциями" для простоты). Большая часть выборок принимает "опции" в качестве необязательного параметра. Если параметр не передан запрос будет выполнен с пустыми опциями.

$productModel = ProductModel::getInstance();
    
    $sql = "select * from product where id = 60 AND status = 'active'";    
    
    $productId = 60;
    $status = 'active';
    
    $productOpts1 = $productModel->getCond()
        ->where(array(
            'id' => $productId,
            'status' => $status
        ));
    $product1 = $productModel->getProduct($productOpts1);
        
    
    $productOpts2 = $productModel->getCond()
        ->where('id = ?', $productId)
        ->where('status = ?', $status);
    $product2 = $productModel->getProduct($productOpts2);
    
    
    $productOpts3 = $productModel->getCond()        
        ->where(array(
            'status' => $status
        ));
    
    $product3 = $productModel->getProductByProduct($productId, $productOpts3);
    $product4 = $productModel->getProductByProduct($product3, $productOpts3);
    
В примере показано аж 3 способа получения одного и того же продукта. 

О способах 1 и 2. Метод where может принимать на вход массив или строку. 

Способ номер 1 наиболее предпочтительный и использует массив. В массив можно предавать несколько параметров - они будут соединяться по условию AND. Т.е. 
    
    ->where(array('id' => 60, 'status' => 'active')); 
    эквивалентно WHERE id = 60 AND status = 'active'; 
    
Все параметры передаваемые через массив пройдут через prepared statement, что исключит возможность sql-инъекции. 
    
В способе номер 2 where принимает строку. При этом параметры биндятся, т.е. вместо вопросиков подставятся переданные параметры и опять же пройдут через prepared statement. Поэтому, если вы пользуетесь строкой то ОБЯЗАТЕЛЬНО подставляйте параметры через bind,а не конкатенацией строк. Здесь жи видно, что можно несколько раз использовать where и параметры переданные в разные where будут также объединться по условию AND. Можно даже делать несколько where и в один передавать массив, а в другой строку. 

Способ номер 3, это автоматически сгенеренный метод getProductByProduct, который принимает id продукта или productEntity и по ним достает продукт из базы. Если залезть внутрь метода то видно, что это проксирующий метод над getProduct. Метод getProductByProduct принимает необязательный параметр кондиций в нем уже не нужно указывать айдишник продукта, а только дополнительный опции.

Подведем краткий итог по тому как юзать where

    <ТАК ДЕЛАТЬ НЕЛЬЗЯ> 
        ->where('id = ' .  $productId) 
    </ТАК ДЕЛАТЬ НЕЛЬЗЯ>
    
    <ТАК ДЕЛАТЬ ЛЬЗЯ> 
        ->where('id = ?', $productId) 
    </ТАК ДЕЛАТЬ ЛЬЗЯ>
    
    <ТАК ДЕЛАТЬ НУЖНО> 
        ->where(array('id' => $productId, 'status' => 'active')); 
    </ТАК ДЕЛАТЬ НУЖНО>
    
    P.S Еще в особо загонных запросах можно передавать в where Zend_Db_Expr, например
    ->where(new Zend_Db_Expr('DATE_ADD(admin_history_stat.task_history_sent_date, INTERVAL admin.period_notice MINUTE) < "' . $date . '"'));
    
    
Для того, чтобы посмотреть, как использовать другие операторы SQL рассмотрим такой запрос

    SELECT product.id, product.name, product.price, COUNT(product.id) AS image_count FROM `product`
    JOIN product_image ON product_image.product_id = product.id
    WHERE product.price > 100 AND product.primary_rubric_id = 228 AND product.status = 'active'
    GROUP BY product.id
    HAVING image_count > 5
    ORDER BY product.name

Что он делает? Он выбирает нам данные по продуктам, которые дороже 100, у которых главная рубрика 228 и главное - к ним привязано больше 5 картинок. И вывод сортирует по имени продукта. 


Рассмотрим аналог выборки через модели

    $productListOpts = ProductModel::getInstance()->getCond()
        ->columns(array('product.id', 'product.name', 'product.price', 'image_count' => 'COUNT(product.id)'))
        ->join(ProductModel::JOIN_PRODUCT_IMAGE)
        ->where('price > ?', 100)
        ->where(array(
            'product.primary_rubric_id' => 228,
            'product.status' => 'active'
        ))
        ->group('product.id')
        ->having('image_count > ?', 5)
        ->order('product.name')
        ->showQuery(true);
    $productList = ProductModel::getInstance()->getProductList($productListOpts);
    
    print_r($productList->toArray());
    die();
    
Обратим внимание сразу на последнюю строчку опций ->showQuery(true); Эту опцию можно добавлять в кондиции для отладки. 
Когда запрос будет выполняться, то во время выполнения запроса сформированынй sql выведется в  html комментариях в тело ответа. Главное не забыть убрать эту строчку перед деплоем на продакшен,а то можно какой-нить json в аяксовом запросике поломать да и вообще даж в комментах не хорошо сорить sql-никами) 
Для данного запроса выведется следующий сформированный sql-ник.

    <!-- FETCH ALL:
        TIME: 0.0013201236724854
        QUERY:
            SELECT `product`.`id`, `product`.`name`, `product`.`price`, COUNT(product.id) AS `image_count` FROM `product`  INNER JOIN `product_image` ON `product`.`id` = `product_image`.`product_id` WHERE (price > 100) AND (product.primary_rubric_id = 228 ) AND (product.status = 'active' ) GROUP BY `product`.`id` HAVING (image_count > 5) ORDER BY `product`.`name` ASC
    -->

Он совпадает с тем чистым sql-ником, который мы хотели получить. Занчит мы все сделали правильно. Теперь рассмотрим что же наделали

    ->columns(array('product.id', 'product.name', 'product.price', 'image_count' => 'COUNT(product.id)'))
указали какие выбирать колонки, если эта опция не добавлена в кондиции, то по умолчанию выбирается все, т.е. будет подставлена *. Для COUNT(product.id) мы задали alias image_count - он прописывается в ключе к элементу массива. 

    ->join(ProductModel::JOIN_PRODUCT_IMAGE)
здесь мы указываем что нашу табличку нужно заджойнить с таблицей картинок. На моменте генерации моделей генеартор анализирует ваши таблицы и их связи. Соответветсвенно если вы создавала таблицы в соответствии с нотацией https://github.com/esteit/edu/blob/master/mysql/standart.md т.е. правильно назвали таблицы и ключи,проставили связи, то модели нагенерят вам возможных join-ов. Т.е. ProductModel уже содержит константы
    
    /**
    * Добавить JOIN-сущность product_image
    */
    const JOIN_PRODUCT_IMAGE = 'product_image';

    /**
    * Добавить JOIN-сущность product_info
    */
    const JOIN_PRODUCT_INFO = 'product_info';

    /**
    * Добавить JOIN-сущность rubric
    */
    const JOIN_RUBRIC = 'rubric';
    
    /**
    * Добавить JOIN-сущность product_image
    */
    const JOIN_PRIMARY_IMAGE = 'primary_image';

    /**
    * Добавить JOIN-сущность rubric
    */
    const JOIN_PRIMARY_RUBRIC = 'primary_rubric';

    /**
    * Добавить JOIN-сущность product_rubric_link
    */
    const JOIN_PRODUCT_RUBRIC_LINK = 'product_rubric_link';

Для всевозможных стандартных join-ов со связанными таблицами. А внутри ProductModelAbstract уже сгенерен код, который значет, что нужно добавить в sql-ник, чтобы эти join-ы работали. 

Обратим внимание еще на одну штуку **const JOIN_RUBRIC**
Что это значит? Это значит что генератор понял, что у вас есть связь многие ко многим продуктов с рубриками и осуществляется она через таблицу связки product_rubric_link. Соответсвенно, чтобы заджойнить продукты с рубриками вам достаточно написать ->join(ProductModel::JOIN_RUBRIC) а модели уже сами сгенерят вам sql для двух джойнов через таблицу связки.
Кроме обычного иннер джойна можно использовать left join. Надо просто вызвать ->leftJoin(ProductModel::JOIN_PRODUCT_IMAGE) и готов. 
Также для нестандартных выборок можно использовать joinRule. На примере другой базы данных с тикетами
    
    ->joinRule('ticket',
            Model_Cond::JOIN_LEFT,
            'ticket',
            'ticket.id = ticket_admin_link.ticket_id AND ticket.`status` = "active" AND ticket.folder = "inbox"'
        )
первым параметром указывается какая entity будет сформирована в результате запроса (у нас TicketEntity), вторым - тип джойна - inner,left,right,cross, третьим - таблица с которой джойнится данная, и четвертым параметром строчка в которой собтсвенно написано по какому условию джойнить.

    ->where('price > ?', 100)
    ->where(array(
        'product.primary_rubric_id' => 228,
        'product.status' => 'active'
    ))
Про where уже было написано до, поэтмоу кратко напомним, что разные where объединяются по условию AND, что лучше использовать массив в where, но для случаев когда нельзя написать через массив, то можно использовать строку с биндеными параметрами. 

    ->group('product.id')
    ->having('image_count > ?', 5)

Здесь указываем почем групировать и добавляем условие для групп. Вообще having не обязателен,можно использовать и просто group. В group можно передавать массив строчек,если группировка идет по несольким сотлбцам. 

    ->order('product.name')
Обычный order - по чему сортировать.  По умолчанию подставиться ASC. Если нужно соритровать в другую сторону можно написать     

    ->order('product.name DESC')
Также в этой же строке можно указывать другие поля, если сортировка идет по нескольким полям, также как вы бы писали это в mysql или же передать массив строк.


Кроме уже рассмотренных опций есть еще limit, offset, distinct, page, with, cond и некоторые другие.

 limit, offset, distinct довольно очевидны -  limit, offset принимают числа и работают так же как и обычный sql-ные. distinct - добавляет DISTINCT к запросу. 
 
 page - это такой сахар над лимитом и оффсетом, который удобно исопльзовать для пагинации. 
    
    ->page(3, 25)
Первым параметром принимает номер страницы, вторым по сколько на страницу выбирать строк. Т.е. в нашем примере получается, что нужно пропустить первые 50 записей и выбрать следующие 25. 

##WITH
Одна из самых интересных частей моделей - это with. 
Это такая классная штука которая умеет доставать связанные данные из разных табличек. На примере будет понятнее.
У нас есть продукт и нам нужно достать его вместе с его инфо. Давайте сделаем это через модели

    $productId = 60;
    $productOpts = ProductModel::getInstance()->getCond()
        ->with(ProductModel::WITH_PRODUCT_INFO);
    $product = ProductModel::getInstance()->getProductByProduct($productId, $productOpts);

    print_r($product->toArray(true));
    die;
    
    /*
    Array
    (
        [id] => 60
        [name] => iMac 21,5-дюймовый 2,9 ГГц
        [price] => 2
        [delivery_price] => 
        [primary_image_id] => 76
        [primary_rubric_id] => 224
        [slug] => imac-21-5-dyujmovyj-2-9-ggts
        [path] => /elektronika/kompyutery/nastolnye-kompyutery/imac-21-5-dyujmovyj-2-9-ggts
        [path_hash] => aea6e89b5ba94f5dc1a552a140dda7c179207251
        [status] => inactive
        [modify_date] => 2014-02-25 12:51:34
        [create_date] => 2014-02-04 14:55:19
        [_product_info] => Array
            (
                [id] => 57
                [product_id] => 60
                [description] => <p>Тип процессора Core i5<br />Частота процессора 2,9-3,6 ГГц<br />Размер оперативной памяти 8 Гб<br />Объем накопителя 1 Тб<br />Размер экрана 21.5 дюйм<br />Видеопроцессор Intel NVIDIA GeForce GT 750M c 1 Гб видеопамяти<br /><br /></p>
            )
    
    )
    */
    
Вот так вот просто ->with(ProductModel::WITH_PRODUCT_INFO); мы решили задачу с помощью наших моделей. 
Как это работает? Если посмотреть на структуру нашей базы данных то мы увидим что в таблице product_info есть поле product_id. Для этого поля проставлена связь 
    
    ALTER TABLE `product_info`
          ADD CONSTRAINT `product_info_ibfk_1` FOREIGN KEY (`product_id`) REFERENCES `product` (`id`) ON DELETE CASCADE ON UPDATE CASCADE;
          
Генератор моделей умеет анализировать связи таблиц и генерировать with, для того,чтобы было проще доставать связанные данные. 

Т.е. генератор смотрит, что таблица product_info связана с таблицей product и генерит нам ProductModel::WITH_PRODUCT_INFO 
Как это работает дальше - мы указываем в опциях выборки продукта ->with(ProductModel::WITH_PRODUCT_INFO), далее модель **выбирает нам продукт, ПОСЛЕ ЭТОГО смотрит на указанные with-ы и достает связанные сущности ОТДЕЛЬНЫМИ ЗАПРОСАМИ**. 
    
Таким образом мы можем досавать не толкько связанные сущносит по свзяи один-к-одному, но и вообще любые связанные сущности
    
    ->with(ProductModel::WITH_PRODUCT_INFO)
    ->with(ProductModel::WITH_PRIMARY_IMAGE)
    ->with(ProductModel::WITH_PRODUCT_IMAGE_LIST)
    ->with(ProductModel::WITH_RUBRIC_LIST)
    
С помощью такой выборки мы достанем вместе с entity продукта, еще и его инфо ProductInfoEntity, и главную картинку в виде  ProductImageEntity (потому что primary image это тоже картинка), и весь список картинок в виде ProductImageCollection, и список рубрик, которым принадлежит продукт в виде RubricCollection. Т.е. будут выполнены дополнительные 4 запроса, после того, как будет достан продукт, для выбора связанных сушностей. 

Давайте подумаем о такой задаче: допустим нам нужно достать рубрику вместе с товарами рубрики, причем товары нужно достать вместе с инфой по товарам, еще нужно достать картинки товара, но не более 3х. Давайте реализуем эту выборку через модель

    $rubricOpts = RubricModel::getInstance()->getCond()
        ->with(RubricModel::getInstance()->getCond(RubricModel::WITH_PRODUCT_LIST)
            ->with(ProductModel::WITH_PRODUCT_INFO)
            ->with(ProductModel::getInstance()->getCond(ProductModel::WITH_PRODUCT_IMAGE_LIST)
                ->limit(3)
            )
        );

    $rubricId = 224;
    $rubric = RubricModel::getInstance()->getRubricByRubric($rubricId, $rubricOpts);
Посмотрим что у нас получилось. Первое,что нужно отметить, это то, что with может принимать строку как здесь ->with(ProductModel::WITH_PRODUCT_INFO), а может принимать объект кондиций. 
Возможность передавать строчку -это синатксический сахар, по факту внутри with написано 
    
    public function with($cond)
    {
        if (is_scalar($cond)) {
            $cond = new self($cond);
        } elseif (!$cond instanceof Model_Cond) {
            throw new Model_Exception('Cond must be instance of Model_Cond');
        }
        $this->_params['with'][$cond->getEntity()] = $cond;
        return $this;
    }
    
Таким образом, даже если вы передали строку, внутри with все равно будет создан объект Model_Cond соответствующий переданной строке. Т.е. в Model_Cond создается для какой-то сущности. Например, когда мы пишем ProductModel::getInstance()->getCond() то мы получаем объект кондиций, соответсвующий ProductEntity. Тоже самое когда пишем  ->with(ProductModel::WITH_PRODUCT_INFO) то внутри with-а создается объект кондиций соотвествующий const WITH_PRODUCT_INFO = 'product_info'; т.е. ProductInfoEntity. Или можно самому создать объект кондиций и передать в with. Соответственно если мы сами создаем объект кондиций, то мы можем изменять выборку как и при обычной выборке. Это хорошо понятно на примере 
    
    ->with(ProductModel::getInstance()->getCond(ProductModel::WITH_PRODUCT_IMAGE_LIST)
        ->limit(3)
    )
Мы передали внутрь with объект кондиций соответствющий  const WITH_PRODUCT_IMAGE_LIST = 'product_image_list';  
"Откуда же модель знает какие entity надо создавать для product_image_list?" - спросите вы. Эти правили прописаны в ProductEntityAbstract в методе _setupRelatedTypes автоматически сгенирированном. 

    protected function _setupRelatedTypes()
    {
        $this->_relatedTypes = array('_product_image' => 'ProductImageEntity',
                                     '_product_image_list' => 'ProductImageCollection',
                                     '_product_image_count' => self::DATA_TYPE_INT,
                                     '_product_info' => 'ProductInfoEntity',
                                     '_rubric' => 'RubricEntity',
                                     '_rubric_list' => 'RubricCollection',
                                     '_rubric_count' => self::DATA_TYPE_INT,
                                     '_primary_image' => 'ProductImageEntity',
                                     '_primary_rubric' => 'RubricEntity');
    }

Т.е. здесь указано, что _product_image_list будет соответствовать ProductImageCollection. Переопределяя этод метод и некоторые другие в дальнейшем мы сможем писать собственные with-ы, но об этом позже. 
Вернемся к нашей выборке. 

    ->with(ProductModel::getInstance()->getCond(ProductModel::WITH_PRODUCT_IMAGE_LIST)
        ->limit(3)
    )
    
Мы получили объект кондиций для ProductImage и в нем указали, что нам нужно будет не больеш 3х картинок. 
Т.е. внутрь with мы можем передавать кондици и применять к ним все те же методы,что и к обычным выборкам. Это позволяет нам, например, передавать внутрь with кондиции с другими with-ами. Так мы и сделали с рубриками и продуктами

    ->with(RubricModel::getInstance()->getCond(RubricModel::WITH_PRODUCT_LIST)
        ->with(ProductModel::WITH_PRODUCT_INFO)
        ->with(ProductModel::getInstance()->getCond(ProductModel::WITH_PRODUCT_IMAGE_LIST)
            ->limit(3)
        )
    );

Мы написали, что нужно достать рубрики, вместе с продуктами, а продукты вместе с инфо и картинками,при этом количество кратинок мы ограничили. 

В предыдущем запросе мы получили одну рубрики с продуктами и связанными данными. Что делать,если нам нужно получить несколько рубрик с такими же данными. Например, задача такая же как предыдущая, но нужно получить данные по рубрикам 224, 201.  

    $rubricOpts = RubricModel::getInstance()->getCond()
        ->with(RubricModel::getInstance()->getCond(RubricModel::WITH_PRODUCT_LIST)
            ->with(ProductModel::WITH_PRODUCT_INFO)
            ->with(ProductModel::getInstance()->getCond(ProductModel::WITH_PRODUCT_IMAGE_LIST)
                ->limit(3)
            )
        );

    $rubricIds = array(224, 201);
    $rubricList1 = RubricModel::getInstance()->getRubricListByRubric($rubricIds, $rubricOpts);

    $rubricOpts->where(array('id' => $rubricIds));
    $rubricList2 = RubricModel::getInstance()->getRubricList($rubricOpts);

Объект кондиций $rubricOpts  не изменился. Для выборки через IN можно воспользоваться сгенереным методом getRubricListByRubric или добавить ->where(array('id' => $rubricIds))  - модели поймут, что передан массив и сами подставят IN.
Нужно понимать, что with использует отдельные запросы. Т.е например для выбора рубрики с продуктами и инфо и картинками количество запросов будет примерно рассчитываться вот так: 
Запрос на рубрику + отдельный запрос на получение продуктов + для каждого продукта еще запрос на получение инфо + для каждого продукта еще запрос на получение картинок= 1 + 1 + product_count + product_count = 2 + 2 * product_count. 
Соответственно, если достается product_count = 5 - т.е. 5 продуктов,то query_count = 12 запросов. Соответственно нужно быть аккуратными с with, когда достаются коллеции, за счет большего количества запросов выборка может подтупливать. Но в общем случае with работает хорошо и быстро. 

Подведем итоги:
- Модели позволяют строить практически любые выборки
- Модели предоставляют возмонжность для удобного выбора related-данных и related-данных related-данных и так далее, ну вы поняли  =)
- WITH выполняется отдельным запросом, что может повлиять на производительность при больших выборках.


##Add, Update, Import
Мы научились выбирать данные. Посмотрим как же добавлять и изменять данные в базе данных. 

###Add
Аналогом sql insert в моделях является метод add%EntityName%. Продолжим рассматривать на примере нашей тестовой бд. 
Добавим продукт 
    $productData = array(
        'name' => 'Test product',
        'price' => 200,
        'primary_image_id' => 224,
        'slug' => 'test_product',
    );

    $addResult = ProductModel::getInstance()->addProduct($productData);

    if ($addResult->isError()) {
        print_r($addResult->getErrorsDecorated()->toLogString());
    } else {
        $productId = $addResult->getResult();
        $product = ProductModel::getInstance()->getProductByProduct($productId);
        print_r($product->toArray());
    }
        
Вот так незамысловато добавляется продукт в бд. Нужно просот заполнить массив с данными и передать в метод addProduct.

###Model_Result
Вставка, апдейт и импорт(об этом позже) возвращают объект Model_Result. Это объект содержащий результат выполнения операции. В примере мы проверили что result с ошибкой - isError  и сказали, что если есть ошибки, то нужно их вывести. Если ошибок нет, то $addResult->getResult() вернет айдишинк вставленной записи.
Желательно, чтобы все ваши написанные методы в моделях, изменяющие базу данных возвращали Model_Result. 
Model_Result может содержать дочерние Model_Result. Зачем это нужно? Допустим вы можете за раз в своей функции менять несколько сущностей. Маленький пример

    $result = new Model_Result();
    foreach ($productListByPrimaryRubric as $product) {
        $childResult = $this->updateProductPathByProduct($product, $primaryRubric);
        $result->addChild('rebuildProductListPathByPrimaryRubric ' . $product->getId(), $childResult);
        if ($childResult->isError()) {
            return $result;
        }
    }

Здесь мы апдейтим несколько продуктов с помощью самописного метода updateProductPathByProduct возвращающего Model_Result.
Мы складываем все результыты в один общий Model_Result $result. Когда мы у него вызовем $result->isError() или $result->isValid() то будет проверен не только этот Model_Result  но и все его дочерние.


Попробуем вставить даныне с ошибкой. В предыдущий пример передадим вот такой массив

    $productData = array(
        'price' => 200,
        'primary_image_id' => 224,
        'slug' => 'test_product',
    );
Т.е. мы не передали обязательный параметр 'name'.
Произойдет ошибка и $addResult->isError() будет тру. Модели могут выявить ошибку на стадии фильтрации данных и вернуть ее в Model_Result или же получить ошибку от Mysql и вставить туда же model_result.
    
    
###Update
Операция обновления данных очень похожа на вставку. 

     $result = new Model_Result();

    $productId = 179;
    $productData = array(
        'name' => 'Test product1',
        'id' => $productId
    );
    $updateResult = ProductModel::getInstance()->updateProduct($productData);
    $result->addChild('usual product update', $updateResult);

    $productData2 = array(
        'name' => 'Test product2',
    );
    $updateResult2 = ProductModel::getInstance()->updateProductByProduct($productId, $productData2);
    $result->addChild('Update product by id', $updateResult2);

    $productData3 = array(
        'name' => 'Test product3',
    );
    $updateProductOpts = ProductModel::getInstance()->getCond()->where(array('name' => 'Test product2'));
    $updateResult3 = ProductModel::getInstance()->updateProduct($productData3, $updateProductOpts);
    $result->addChild('Update product by condition', $updateResult3);
    
    if ($result->isError()) {
        print_r($result->getErrorsDecorated()->toLogString());
    }
    die;
    
Здесь показаны 3 примера - как проапдейтить данные. Второй пример это тот же первый, только с использованием синтаксического сахара моделей - метода updateProductByProduct. 
Третий же метод использует кондиции и проапдейтит не одну запись, а все записи, у которох 'name' => 'Test product3'

Здесь же еще рассмотрим связку многие-ко-многим. Вот так вяжутся записи через таблицу связки
    
    $productId = 245;
    $rubricId = 234;    
    ProductModel::getInstance()->linkProductToRubric($productId, $rubricId);
    ProductModel::getInstance()->linkProductToRubric($productId, $rubricId, false);
    
Просто вызываем метод linkProductToRubric - и он добавляет связку продукта с рубрикой. Этот метод принимает третий необязательный параметр $isAppend = true - если этот параметр поставить в false, то сначала будет удалены все связки этого продукта с рубриками, а потом уже будет добавленя новая.

###Import
Кроме стандартных для баз данных методов вставки и апдейта модели имеют еще один метод - import. У него есть несколько особенностей - он умеет проверять существует ли запись уже и если не существует, то добавлять, а если существует, то апдейтить. И еще одна возможность - импорт умеет добавлять за раз не толкьо саму сущность, но и связанные сущности. Рассмотрим по очереди.

####Вставить или проапдейтить

    //import product -  add it
    $productData = array(
        'name' => 'Test product5',
        'price' => 200,
        'primary_image_id' => 224,
        'slug' => 'test_product5',
    );
    $importOpts = Model_Import_Cond::init(true,true,true);
    $importResult = ProductModel::getInstance()->importProduct($productData, $importOpts);   
    if ($importResult->isError()) {
        print_r($importResult->getErrorsDecorated()->toLogString());
    } else {
        $productId = $importResult->getResult();
        $product = ProductModel::getInstance()->getProductByProduct($productId);
        print_r($product->toArray());
    }


    //import product - update it by id
    $productData = array(
        'id' => 184,
        'name' => 'Test product6'
    );
    $importOpts = Model_Import_Cond::init(true,true,true);
    $importResult = ProductModel::getInstance()->importProduct($productData, $importOpts); 
    if ($importResult->isError()) {
        print_r($importResult->getErrorsDecorated()->toLogString());
    } else {
        $productId = $importResult->getResult();
        $product = ProductModel::getInstance()->getProductByProduct($productId);
        print_r($product->toArray());
    }


    //import product - update it by path_hash
    $productData = array(
        'path_hash' => 'fb32ab2cc85944c366452edcbe0fd5a342eeaf83',
        'name' => 'Test product7'
    );
    $importOpts = Model_Import_Cond::init(true,true,true);
    $importResult = ProductModel::getInstance()->importProduct($productData, $importOpts);   
    if ($importResult->isError()) {
        print_r($importResult->getErrorsDecorated()->toLogString());
    } else {
        $productId = $importResult->getResult();
        $product = ProductModel::getInstance()->getProductByProduct($productId);
        print_r($product->toArray());
    }
    
Здесь мы 3 раза проделали операцию импорта. Обратим внимание на парметры импорта. Имопрт принимает массив данных для вставки/апдейта и опции Model_Import_Cond. В этих опциях можно указать напрмиер что updateAllowed = false - в таком случае если запись не найдено по переданны данным то будет вставка, а если найдена, то апдейта не будет. И некоторые другие опции. Их мы рассмотрим позже. 
Так что же мы сделали. В первом примере мы передали данные в импорт. Внутри себя импорт пытается достать из переданных данных те данные, по которым можно было бы попробовать одназачно найти такую запись в бд - в основном это поля на которые наложены уникальные ключи. 
В нашем первом примере таких полей нет. Соответственно импорт просто создаст продукт и в резалт положит айдишник созданного продукта. 
Во втором и третьем примере импорт сможет найти записи по переданному id или path_hash(на него наложен уникальный ключ в базе) и так как в опциях Model_Import_Cond::init(true,true,true); трьим параметро мы передали $updateAllowed = true, то импорт найдет такие записи и их проапдейтит. Если таких записей не было бы импорт попробовал бы создать такую запись (и возможно свалился бы из-за того, что мы не передали обязательный slug, но в моей базе записи с таким айдишником и  path_hash есть так что у меня все норм=)). 

##Вставка связанных данных
У импорта есть такая крутая штука, которой нет у add и update - он может вставлять связанные данные. Пример - 

    $productData = array(
        'name' => 'Test product6',
        'price' => 200,
        'primary_image_id' => 224,
        'slug' => 'test_product6',
        '_product_info' => array(
            'description' => 'abra kadabra!'
        ),
        '_product_image_list' => array(
            array(
                'filename' => 'test_file',
                'fileextension' => 'jpg',
                'filepath' => '/tmp',
                'filehash' => '3b15be84aff20b322a93c0b9aaa62e25ad33b4b1',
                'filesize' => '775703'
            ),
            array(
                'filename' => 'test_file2',
                'fileextension' => 'jpg',
                'filepath' => '/tmp',
                'filehash' => '3b15be84aff20b322a93c0b9aaa62e25ad33b4b2',
                'filesize' => '775704'
            ),
        ),

    );
    $importOpts = Model_Import_Cond::init(true,true,true);
    $importResult = ProductModel::getInstance()->importProduct($productData, $importOpts);
    if ($importResult->isError()) {
        print_r($importResult->getErrorsDecorated()->toLogString());
    } else {
        $productId = $importResult->getResult();

        $product = ProductModel::getInstance()->getProductByProduct($productId);
        print_r($product->toArray());
    }
    
Что делают эти много букав? Да просто мы кроме создания товара, еще сразу создали инфу по нему и картиночки (заливание самих файлов здесь не рассматривается, только записи в бд). 
**Related данные всегда пишутся начинаются с подчеркивания**. Мы передали _product_info и _product_image_list. Как уже упомяналось раньше 
> "Откуда же модель знает какие entity надо создавать для product_image_list?" - спросите вы. Эти правили прописаны в ProductEntityAbstract в методе _setupRelatedTypes автоматически сгенирированном. 

Заметьте в связанных данных мы не указываем product_id (тем более что он при вставке заранее неизвестен) - модель сама знает, что при импорте нужно импортнуть сначала саму сущность, а потом related сущность и при этом проставить related сущности product_id вставленной записи.
Зачем нужна возможность импортить related сущности? Это удобно! Можно не писать стопиццот вставок и при этом каждый раз получать вставленный айдишник и проставлять его при вставке связанных сущностей. Горазждо проще импортнуть все за раз. 

##Удаление
Удаление очень похоже на update - можно удалить передав опции, где указано какие записи удалять, можно воспользоваться спецаильным методом deleteProductByProduct. Отдельно генерятся методы для удаения связей многие-ко-многим.
        $productId = 245;
        $productOpts = ProductModel::getInstance()->getCond()->where(array('id' => $productId));
        ProductModel::getInstance()->deleteProduct($productOpts);
        ProductModel::getInstance()->deleteProductByProduct($productId);
        $rubricId = 234;
        ProductModel::getInstance()->deleteLinkProductToRubric($productId, $rubricId);
