const store = Vue.observable({
    debug: true,
    config: {
        data: null,
        error: null
    },
})

const actions = {
    setConfig (newConf) {
        if (this.debug) console.log('setConfig triggered with', newConf)
        state.config.data = newConf
    },
    fetchConfig: async function () {
       const response = await axios.get('/config').catch(function(e){
            store.config.error = e
        })
        store.config.data = response.data
    }
}

Vue.prototype.$store = store
Vue.prototype.$actions = actions
Vue.prototype.$nav = Vue.observable({ current: 'Dashboard'})
