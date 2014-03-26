Здесь мы рассмотрим как работать с выбранными данными. Мы уже рассмотрели как выбирать данные в https://github.com/esteit/edu/blob/master/models/model.md . Давайте научимся работать с выбранными данными

#Entity
Мы уже знаем, что когда мы делаем запрос к базе на выбор какой-нибудь одной записи, то модель возвращает нам результат в виде entity, в которой хранятся выбранные данные. 

Например 

    $productModel = ProductModel::getInstance();
    $productId =  60;
    $product = $productModel->getProductByProduct($productId);
Какие поля у нас есть у продукта id, name, price, primary_image_id, primary_rubric_id, slug, path, path_hash, status, 
create_date, modify_date

Давайте что-нибудь выведем по полученному продукту

    $productModel = ProductModel::getInstance();
    $productId =  60;
    $product = $productModel->getProductByProduct($productId);

    echo ' Product : ' . $product->getId();
    echo "\n Name :" . $product->getNameAsStringDecorator()->strToLower();
    echo "\n Price : " . $product->getPrice();
    echo "\n Primary Image Id : " . $product->getPrimaryImageId();
    echo "\n Slug : " . $product->getSlug();
    if ($product->isActive()) {
        echo "\n Product is active";
    } else {
        echo "\n Product status : " . $product->getStatus();
    }
    echo "\n Product created at : " . $product->getCreateDateAsDateDecorator()->format('Y-m-d');
    echo "\n Product modified at : " . $product->getModifyDate();
 -

    /**
    Result
              
    Product : 60
    Name :imac 21,5-дюймовый 2,9 ггц
    Price : 2
    Primary Image Id : 76
    Slug : imac-21-5-dyujmovyj-2-9-ggts
    Product status : inactive
    Product created at : 2014-02-04
    Product modified at : 2014-03-24 17:43:52
     */

Что мы видим? Что для всех полей генерятся обычные геттеры - getId, getPrice и так далее, которые просто возвращают нам данные. Кроме для полей типа string и date модель автоматически генерит методы для получения этих полей в виде декораторов. Для примера мы получили имя продукта в виде StringDecorator и используя его привели имя к нижнему регистру, а дату создания в виде DateDecorator и вывели толкьо год, месяц и день без часов/минут/секунд.  Для полей типа enum модели генерят методы начинающиейся на is - для проверки равентсва поля конретному значению. Например чотбы вам не приходилось сравнивать status со строкой "active", генератор создал метод isActive, который внутри себя делает это за вас
    
    public function isActive()
    {
        return $this->getStatus() == 'active';
    }
    
Обычно для всех полей типа enum генератор вшивает имя поля в название метода, например если бы у нас было поле тип со значениями например = enum("new", "used"), чтобы пометить какие товары новые, а какие б/у, то генератор создал бы методы isTypeNew и isTypeUsed, но именно для поля status слово status не добавляется, так как все знают, что такие методы работают по статусу. 

Давайте посмотрим еще пример

    $product = new ProductEntity();
    echo ($product->exists() ? ' Product exists'  : ' Product not exists' );
    echo "\n Product : ";
    var_dump($product->getId());
    echo "\n Name :";
    var_dump($product->getNameAsStringDecorator()->strToLower());
    echo "\n Price : ";
    var_dump($product->getPrice());
    echo "\n Primary Image Id : ";
    var_dump( $product->getPrimaryImageId());
    echo "\n Slug : ";
    var_dump($product->getSlug());
    if ($product->isActive()) {
        echo "\n Product is active";
    } else {
        echo "\n Product status : ";
        var_dump($product->getStatus());
    }
    echo "\n Product created at : ";
    var_dump($product->getCreateDateAsDateDecorator()->format('Y-m-d'));
    echo "\n Product modified at : ";
    var_dump($product->getModifyDate());
 -

    /**
     Result 
    
     Product not exists
     Product : int(0)    
     Name :string(0) ""    
     Price : float(0)    
     Primary Image Id : int(0)    
     Slug : string(0) ""    
     Product status : string(0) ""    
     Product created at : string(10) "2014-03-26"    
     Product modified at : string(0) ""
     */
    
Что мы видим? Что для пустой entity действуют все те же методы, что и для entity с данными. Как мы можем получить пустую entity? Создать ее в коде руками,или, что более вероятно запросить из базы какую-то запись которой нет. 
Например 

$productModel = ProductModel::getInstance();
    $productId =  60000000000000;
    $product = $productModel->getProductByProduct($productId);
вернет нам пустую entity в качестве результата (если у нас конечно нет продукат с таким айдишником). Соответственно мы можем определить пустая entity или нет с помощью метода exists. Вызов остальных геттеров будет возвращать нам дефолтное значение поля в зависимости от типа поля - для строк пустую строчку, для чисел 0,для bool false и так далее. Зачем это сделано? Здесь используется паттерн проектирования Особый Случай (Special Case) - http://design-pattern.ru/patterns/special-case.html для того,чтобы вам не приходилось лепить кучу проверок на null.

Как получать данные этой сущности мы разобрались. Как же получать related сущности?

###Получение related данных
Пример запроса

    $productModel = ProductModel::getInstance();
    $productOpts = ProductModel::getInstance()->getCond()
        ->with(ProductModel::WITH_PRODUCT_INFO)
        ->with(ProductModel::getInstance()->getCond(ProductModel::WITH_PRODUCT_IMAGE_LIST)
                ->limit(3)
        );

    $productId =  60;
    $product = $productModel->getProductByProduct($productId, $productOpts);
    echo ' Product : ' . $product->getId();
    echo "\n Name :" . $product->getName();
    echo "\n Description :" . $product->getProductInfo()->getDescription();
    foreach($product->getProductImageList() as $productImage) {
        echo "\n Image :" . $productImage->getFilename();
    }
    die();
-

    /**
    Result
    Product : 60
    Name :iMac 21,5-дюймовый 2,9 ГГц
    Description :<p>Тип процессора Core i5<br />Частота процессора 2,9-3,6 ГГц<br />Размер оперативной памяти 8 Гб<br />Объем накопителя 1 Тб<br />Размер экрана 21.5 дюйм<br />Видеопроцессор Intel NVIDIA GeForce GT 750M c 1 Гб видеопамяти<br /><br /></p>
    Image :imac-21-5-dyujmovyj-2-9-ggts_70
    Image :imac-21-5-dyujmovyj-2-9-ggts_75
    Image :imac-21-5-dyujmovyj-2-9-ggts_76
     * /
     
 Видим, что генератор создал нам методы для получения related данных getProductInfo, который возвращает нам ProductInfoEntity, и getProductImageList, который возвращает нам ProductImageCollection (которая содержит внутри себя несколько ProductImageEntity). Соответственно получим с помощью этих методов entity или collection мы дальше работаем с ними как обычно. 
 
Обратим внимание на следующий пример

    $productModel = ProductModel::getInstance();
    $productOpts = ProductModel::getInstance()->getCond();

    $productId =  60;
    $product = $productModel->getProductByProduct($productId, $productOpts);
    echo ' Product : ' . $product->getId();
    echo "\n Name :" . $product->getName();
    echo "\n Description :";
    var_dump($product->getProductInfo()->getDescription());
    var_dump($product->getProductInfo());
    die();
-

    /**
    Result
    
     Product : 60
     Name :iMac 21,5-дюймовый 2,9 ГГц
     Description :string(0) ""
     object(ProductInfoEntity)#115 (5) {
      ["_data":protected]=>
      array(3) {
        ["id"]=>
        int(0)
        ["product_id"]=>
        int(0)
        ["description"]=>
        string(0) ""
      }
      ["_autoAssignedData":protected]=>
      array(3) {
        ["id"]=>
        int(1)
        ["product_id"]=>
        int(1)
        ["description"]=>
        int(1)
      }
      ["_related":protected]=>
      array(0) {
      }
      ["_relatedTypes":protected]=>
      array(1) {
        ["_product"]=>
        string(13) "ProductEntity"
      }
      ["_dataTypes":protected]=>
      array(3) {
        ["id"]=>
        string(3) "int"
        ["product_id"]=>
        string(3) "int"
        ["description"]=>
        string(6) "string"
      }
    }
    */

    
Что мы здесь видим? Мы не передали в опциях ->with(ProductModel::WITH_PRODUCT_INFO). Когда же обратились к $product->getProductInfo(), то нам вернулась пустая ProductInfoEntity. Важно знать и понимать почему так - 
- По логике моделей - enity и коллекции предназначены только для хранения и вывода данных
- Из предыдущего пункта вытекает, что entity и коллекции не должны выбирать данные - они должны только получать при создании данные и выводить в том или ином виде
- Соответственно entity не использует ленивые загрузки и если данные не были выбраны, то она просто вернет вам значение по-умолчанию, а для related сущностей значением по умолчанию является пустая Entity или Collection, в зависимости от того, что вы спрашиваете. 

#Collection
Коллекция - это объект для хранения набора entity. Наследуется коллекция от ArrayIterator  и соответственно может итерироваться как обычный массив.

    $productListOpts = $productModel->getCond()->limit(5);
    $productList = $productModel->getProductList($productListOpts);
    foreach($productList as $product) {
        echo $productImage->getName();
    }

Кроме того у коллекции есть ряд полезных методов. К примеру
getIdsAsArray - возвратит нам массив айдишников entity внутри коллекции. 
first - вернет первую entity внутри коллекции и другие. 
и другие.
Еще для древовидных структур (когда в таблице есть parent_id)  генерятся методы представляющие коллекцию в виде дерева (плоского или вложенного)

    /**
     * Получить данные в виде дерева     
     * @return RubricCollection|RubricEntity[]
     */
    public function asTree()    
            
    /**
     * Получить данные в виде плоского дерева     
     * @return RubricCollection|RubricEntity[]
     */
    public function asPlainTree()    


##toArray
И у entity и у collection есть метод toArray. Он возвращает данные в виде массива. в toArray можно передавать тип, который нужно вернуть. Обычно пишется $product->toArray(), когда нужно перевсти в массив данные только по самому продукту (без related данных) и $product->toArray(true) когда нужно, чтобы и related данные присутствовали в массиве.

    $productModel = ProductModel::getInstance();
    $productOpts = ProductModel::getInstance()->getCond()
        ->with(ProductModel::WITH_PRODUCT_INFO)
        ->with(ProductModel::getInstance()->getCond(ProductModel::WITH_PRODUCT_IMAGE_LIST)
                ->limit(2)
        );

    $productId =  60;
    $product = $productModel->getProductByProduct($productId, $productOpts);

    echo "Without related \n";
    print_r($product->toArray());
    echo "\n\nWith related \n";
    print_r($product->toArray(true));
-
    
    /**
    Result
    Without related 
    Array
    (
        [id] => 60
        [name] => iMac 21,5-дюймовый 2,9 ГГц
        [price] => 2
        [primary_image_id] => 76
        [primary_rubric_id] => 194
        [slug] => imac-21-5-dyujmovyj-2-9-ggts
        [path] => /elektronika/kompyutery/nastolnye-kompyutery/imac-21-5-dyujmovyj-2-9-ggts
        [path_hash] => aea6e89b5ba94f5dc1a552a140dda7c179207251
        [status] => inactive
        [modify_date] => 2014-03-24 17:43:52
        [create_date] => 2014-02-04 14:55:19
    )
    
    
    With related 
    Array
    (
        [id] => 60
        [name] => iMac 21,5-дюймовый 2,9 ГГц
        [price] => 2
        [primary_image_id] => 76
        [primary_rubric_id] => 194
        [slug] => imac-21-5-dyujmovyj-2-9-ggts
        [path] => /elektronika/kompyutery/nastolnye-kompyutery/imac-21-5-dyujmovyj-2-9-ggts
        [path_hash] => aea6e89b5ba94f5dc1a552a140dda7c179207251
        [status] => inactive
        [modify_date] => 2014-03-24 17:43:52
        [create_date] => 2014-02-04 14:55:19
        [_product_image_list] => Array
            (
                [0] => Array
                    (
                        [id] => 70
                        [product_id] => 60
                        [filename] => imac-21-5-dyujmovyj-2-9-ggts_70
                        [fileextension] => jpg
                        [filepath] => f/e/f
                        [filehash] => 07f3237565964614fb4442e479e83423f0836039
                        [filesize] => 71901
                        [create_date] => 2014-02-04 14:55:19
                        [modify_date] => 2014-02-04 14:55:19
                    )
    
                [1] => Array
                    (
                        [id] => 75
                        [product_id] => 60
                        [filename] => imac-21-5-dyujmovyj-2-9-ggts_75
                        [fileextension] => jpg
                        [filepath] => 7/7/e
                        [filehash] => 8dbaf5332c1392a9b247454513821570d5c1572b
                        [filesize] => 37414
                        [create_date] => 2014-02-04 14:59:30
                        [modify_date] => 2014-02-04 14:59:30
                    )
    
            )
    
        [_product_info] => Array
            (
                [id] => 57
                [product_id] => 60
                [description] => <p>Тип процессора Core i5<br />Частота процессора 2,9-3,6 ГГц<br />Размер оперативной памяти 8 Гб<br />Объем накопителя 1 Тб<br />Размер экрана 21.5 дюйм<br />Видеопроцессор Intel NVIDIA GeForce GT 750M c 1 Гб видеопамяти<br /><br /></p>
            )
    
    )
    */
