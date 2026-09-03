import './permission'
import './styles/index.scss'
import 'virtual:svg-icons-register'

import { createApp } from 'vue'

import { getConfig } from './api/app'
import App from './App.vue'
import install from './install'

const app = createApp(App)
app.use(install)
app.mount('#app')

getConfig().then((res) => {
    const cabaGoArt = `
   _____      _           _____  ____ 
  / ____|    | |         / ____|/ __ \\
 | |     __ _| |__   __ | |  __| |  | |
 | |    / _\` | '_ \\ / _\` | | |_ | |  | |
 | |___| (_| | |_) | (_| | |__| | |__| |
  \\_____\\__,_|_.__/ \\__,_|\\_____|\\____/
`

    console.log(
        `%c Caba Night総合管理画面 %c v${res.version} `,
        'padding: 4px 1px; border-radius: 3px 0 0 3px; color: #fff; background: #bbb; font-weight: bold;',
        'padding: 4px 1px; border-radius: 0 3px 3px 0; color: #fff; background: #4A5DFF; font-weight: bold;'
    )
    console.log(`%c ${cabaGoArt}`, 'color: #4A5DFF')
})
