1. Избегать legacy формата, в простых конфигах использовать basic формат, а в сложных - advanced. 

**basic формат:**
```
mail.info /var/log/mail.log
mail.err @@server.example.net
```

**advanced формат:**
пример из basic формата будет выглядеть так:
```
mail.err action(type="omfwd" protocol="tcp" queue.type="linkedlist")
```
либо так:
```
if prifilt("mail.info") then {
	action(type="omfile" file="/var/log/maillog")
}

или в одну строку:
if prifilt("mail.info") then action(type="omfile" file="/var/log/maillog")
```




