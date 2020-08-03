const HttpSuccess = 'success'

const store = Vue.observable({
    debug: true,
    config: {
        data: null,
        error: null
    },
})

const service = Vue.observable({ error: null})

const actions = {
    setConfig (newConf) {
        if (this.debug) console.log('setConfig triggered with', newConf)
        state.config.data = newConf
    },
    fetchConfig: async function () {
        return axios.get('/config')
        .then(function(response) {
            console.log(response)
            store.config.data = response.data
            store.config.error = null
            return HttpSuccess
        })
        .catch(e => store.config.error = e)
    },
    activateDb: async function (db) {
        return axios.post('/addDb', {db: db})
        .then(function(response) {
            console.log(response)
            service.error = null
            actions.fetchConfig()
            return HttpSuccess
        })
        .catch(e => service.error = e)
    }
}

Vue.prototype.$store = store
Vue.prototype.$actions = actions
Vue.prototype.$nav = Vue.observable({ current: 'Dashboard'})
Vue.prototype.$service = service
