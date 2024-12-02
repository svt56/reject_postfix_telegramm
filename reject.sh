#!/bin/bash
#sudo apt-get install jq - if you need install jq
token=$(cat ttk) #токен харинтся в файле ttk
# Функция отправки сообщения
function sendtlg {
url="https://api.telegram.org/bot$token/sendMessage"
if [ -z "$3" ]
 then
 curl -s -X POST $url -d chat_id="$2" -d text="$1" -d protect_content="1"
 else
 curl -s -X POST $url -d chat_id="$2" -d text="$1" -d protect_content="1" -d reply_to_message_id="$3"
fi
}
function reject {
message_id=$(echo $1 | jq .result[].message.message_id)
sender_id=$(echo $1 | jq .result[].message.from.id)
#Проверяем права пользователя
#В массив вносятся список id тлегераммов кому можно присылвать сообщения
user_list=(
    "11111111"
    "222222222"
    "3333"
)
if ! [[ " ${user_list[@]} " =~ " ${sender_id} " ]]; then
  sendtlg "GET KEY BROTHER" "$sender_id" "$message_id"
  return
fi
model=$(echo $1 | jq .result[].message.text)
model=${model:1}
model=${model::-1}
string=$model" REJECT SPAM"
sudo sed -i -e "1 s/^/${string}\n/;" /etc/postfix/sender_access
sudo postmap /etc/postfix/sender_access
sudo systemctl restart postfix
text=$string" - WELL done"
sendtlg "$text" "$sender_id" "$message_id"
}

#получаем номер последнего сообщения
message_id=$(curl -s https://api.telegram.org/bot$token/getUpdates?offset={-1} | jq .result[].message.message_id)
OFFSET=$message_id
#проверяем наличие нового сообщения
while true
 do
   sleep 2
  message=$(curl -s https://api.telegram.org/bot$token/getUpdates?offset={-1})
  message_id=$(echo $message | jq .result[].message.message_id)
  if ! [ $message_id == $OFFSET ]
   then
    #Отправляем сообщение
    reject "$message"
    OFFSET=$message_id
  fi
done
