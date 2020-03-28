const Telegraf = require('telegraf')
const Telegram = require('telegraf/telegram')
const express = require('express')
const uuid = require('uuid')

const telegram = new Telegram(process.env.BOT_TOKEN)
const bot = new Telegraf(process.env.BOT_TOKEN)

bot.start((ctx) => ctx.reply('Welcome! '))
bot.help((ctx) => ctx.reply('Send me a sticker'))

bot.hears('hi', (ctx) => {
	console.log(ctx.from)
	let chatId = ctx.from.id
	ctx.reply('Hi There, please fill this form here https://negaamanuel.typeform.com/to/XqnLGE?chatId='+chatId)
})

bot.launch()

const app = express()
const port = 9000

app.get("/health", (req, res) => {
	res.send("UP")
})
app.post('/form', (req, res) => {
	console.log(chatId)
        telegram.sendMessage(chatId, "Hi, we have received your response" + req)
	res.send('Hello World!')
})

app.listen(port, () => console.log(`Example app listening on port ${port}!`))
