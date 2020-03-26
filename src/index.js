const Telegraf = require('telegraf')
const Telegram = require('telegraf/telegram')
const express = require('express')

const telegram = new Telegram(process.env.BOT_TOKEN)
const bot = new Telegraf(process.env.BOT_TOKEN)

bot.start((ctx) => ctx.reply('Welcome! '))
bot.help((ctx) => ctx.reply('Send me a sticker'))

let chatId = null
bot.hears('hi', (ctx) => {
	console.log(ctx.from)
	chatId = ctx.from.id
	ctx.reply('Hi There, please fill this form here https://negaamanuel.typeform.com/to/XqnLGE?botIdentifer=uuid-generated')
})

bot.launch()

const app = express()
const port = 9000

app.post('/form', (req, res) => {
	console.log(chatId)
        telegram.sendMessage(chatId, "Hi, we have received your response")
	res.send('Hello World!')
})

app.listen(port, () => console.log(`Example app listening on port ${port}!`))
