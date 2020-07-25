<template>
    <q-page class="flex flex-center">
        <div v-if="loading" >
            <q-spinner-cube
                color="orange"
                size="5.5em"></q-spinner-cube>
        </div>

        <div v-if="error" class="error">
        {{ error }}
        </div>

        <div v-if="post" class="content">
        <h2>{{ post.title }}</h2>
        <p>{{ post.body }}</p>
        </div>
    </q-page>
</template>

<script>
module.exports = {
    data () {
    return {
      loading: false,
      post: null,
      error: null
    }
  },
  created () {
    this.fetchData()
  },
  watch: {
    // call again the method if the route changes
    '$route': 'fetchData'
  },
  methods: {
    fetchData () {
      this.error = this.post = null
      this.loading = true
    //   // replace `getPost` with your data fetching util / API wrapper
    //   getPost(this.$route.params.id, (err, post) => {
    //     this.loading = false
    //     if (err) {
    //       this.error = err.toString()
    //     } else {
    //       this.post = post
    //     }
    //   })
    }
  }
}
</script>
