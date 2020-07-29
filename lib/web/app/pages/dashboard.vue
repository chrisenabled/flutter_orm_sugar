<template>
    <q-page class="row q-ma-md justify-center">
        <div class="self-center">
            <div v-if="loading" >
                <q-spinner-cube
                    color="orange"
                    size="5.5em"></q-spinner-cube>
            </div>

            <div v-if="error" class="error">
                {{ error }}
            </div>
        </div>
        <div class="column col q-col-gutter-y-xl">
            <div v-if="config" class="row justify-center q-gutter-sm">
                <q-card v-if="Object.keys(config.repositories).length > 0"
                    class="my-card text-white col-md col-xs-12" flat
                    style="background: linear-gradient(to bottom, #1FD2E6, #37C0EE)">
                    <q-card-section class="flex flex-center">
                        <q-avatar color="white" class="shadow-2" text-color="cyan-3" icon="ti-server" />
                    </q-card-section>
                    <q-card-section class="q-pt-none flex flex-center text-h4 text-weight-bolder">
                        {{Object.keys(config['repositories']).length}}
                        <span class="text-caption">DB</span>
                    </q-card-section>
                    <q-card-section class="q-pt-none flex flex-center 
                    text-caption text-light-blue-1 text-weight-bold">
                        Databases
                    </q-card-section>
                </q-card>
                <q-card v-if="Object.keys(config.models).length > 0"
                    class="my-card text-white col-md col-xs-12" flat
                    style="background: linear-gradient(to bottom, #FFA291, #FE2051)">
                    <q-card-section class="flex flex-center">
                        <q-avatar color="white" class="shadow-2" text-color="red-3" icon="ti-layers-alt" />
                    </q-card-section>
                    <q-card-section class="q-pt-none flex flex-center text-h4 text-weight-bolder">
                        {{Object.keys(config['models']).length}}
                        <span class="text-caption">ML</span>
                    </q-card-section>
                    <q-card-section class="q-pt-none flex flex-center text-caption text-red-1 text-weight-bold">
                        Collections
                    </q-card-section>
                </q-card>
                <q-card v-if="getRels != null"
                    class="my-card text-white col-md col-xs-12" flat
                    style="background: linear-gradient(to bottom, #3BB993, #0CA463)">
                    <q-card-section class="flex flex-center">
                        <q-avatar color="white" class="shadow-2" text-color="green-4" icon="ti-link" />
                    </q-card-section>
                    <q-card-section class="q-pt-none flex flex-center text-h4 text-weight-bolder">
                        {{getNoOfRels()}}
                        <span class="text-caption">REL</span>
                    </q-card-section>
                    <q-card-section class="q-pt-none flex flex-center text-caption text-green-1 text-weight-bold">
                        Relations
                    </q-card-section>
                </q-card>
            </div>
            <div v-if="config" class="row q-gutter-md justify-center">
                <q-card class="text-white col-md col-xs-5">
                    <q-card-section class="column justify-end">
                        <div class="row items-baseline">
                            <span class="text-weight-bolder text-body1" 
                            :style="{color: getUsageColor('firestore')}">
                                {{getDbPercent('firestore')}}</span>
                            <q-linear-progress class="col q-ml-sm" 
                            :value="getDbUsage('firestore')" rounded :color="getUsageColor('firestore')" />
                        </div>
                        <div class="text-caption q-mt-xs text-grey-6">Firestore usage</div>
                    </q-card-section>
                </q-card>
                <q-card class="text-white col-md col-xs-5">
                    <q-card-section class="column justify-end">
                        <div class="row items-baseline">
                            <span class="text-weight-bolder text-body1" :style="{color: getUsageColor('sqlite')}">
                                {{getDbPercent('sqlite')}}</span>
                            <q-linear-progress class="col q-ml-sm" 
                            :value="getDbUsage('sqlite')" rounded :color="getUsageColor('sqlite')" />
                        </div>
                        <div class="text-caption q-mt-xs text-grey-6">Sqlite usage</div>
                    </q-card-section>
                </q-card>
                <q-card class="col-md col-xs-5">
                    <q-card-section class="column justify-end">
                        <div class="row items-baseline">
                            <span class="text-weight-bolder text-body1" :style="{color: getUsageColor('api')}">
                                {{getDbPercent('api')}}</span>
                            <q-linear-progress class="col q-ml-sm" 
                            :value="getDbUsage('api')" rounded :color="getUsageColor('api')" />
                        </div>
                        <div class="text-caption q-mt-xs text-grey-6">Api usage</div>
                    </q-card-section>
                </q-card>
                <q-card class="text-white col-md col-xs-5">
                    <q-card-section class="column justify-end">
                        <div class="row items-baseline">
                            <span class="text-weight-bolder text-body1" :style="{color: getUsageColor('sharedPref')}">
                                {{getDbPercent('sharedPref')}}</span>
                            <q-linear-progress class="col q-ml-sm" 
                            :value="getDbUsage('sharedPref')" rounded :color="getUsageColor('sharedPref')" />
                        </div>
                        <div class="text-caption q-mt-xs text-grey-6">SharedPref usage</div>
                    </q-card-section>
                </q-card>
            </div>
        
            <div v-if="config && Object.keys(config.models).length > 0" class="q-pa-md">
                <q-table
                    class="my-sticky-header-table"
                    title="Collection Stats"
                    :data="Object.values(config.models)"
                    :columns="columns"
                    row-key="name"
                    flat
                    bordered
                />
            </div>
        </div>
    </q-page>
</template>

<script>
module.exports = {
    data () {
    return {
      columns: [
        {
          name: 'name',
          required: true,
          label: 'Collection',
          align: 'left',
          field: 'modelName',
          format: val => `${val}`,
          sortable: true
        },
        {
          name: 'fieldsCount',
          align: 'left',
          label: 'No. of Fields',
          field: row => row.modelFields.length,
          sortable: true
        },
        { 
            name: 'database', 
            label: 'Database', 
            align: 'left',
            field: 'repository', 
            sortable: true 
        },
        { 
            name: 'repoName', 
            label: 'Repo/Table', 
            align: 'left',
            field: 'repoName', 
            sortable: true 
        },
        {
          name: 'relationshipsCount',
          label: 'No. of Relationships',
          align: 'left',
          field: row => Object.keys(row.relationships).length,
          sortable: true
        }
      ],
    }
  },
  created () {
    this.fetchConfig()
  },
  watch: {
    // call again the method if the route changes
    // '$route': 'fetchData'
  },
  computed: {
    loading() {
      return this.$store.config.data == null && this.$store.config.error
    },
    config() {
      return this.$store.config.data
    },
    error() {
      return this.$store.config.error
    },
    getRels() {
        var models = Object.values(this.$store.config.data.models);
        if (models != null && models.length > 0) {
            return models.filter((model) => Object.keys(model.relationships).length > 0);
        }
        return null;
    },
  },
  methods: {
    fetchConfig () {
      this.$actions.fetchConfig()
    },
    getDbUsage(dbName) {
        modelsArr = Object.values(this.$store.config.data['models'])
        count = modelsArr.length
        noOfModels = modelsArr.filter((model) => model['repository'] == dbName)
        if (noOfModels == 0) return 0
        return (noOfModels.length/count).toFixed() || 0
    },
    getDbPercent(dbName) {
        return (this.getDbUsage(dbName) * 100) + '%'
    },
    getUsageColor(dbName) {
        percent = this.getDbUsage(dbName)
        if (percent <= 0.30) return 'red'
        if (percent <= 0.49) return 'orange'
        if (percent <= 0.70) return 'blue'
        return 'green'
    },
    getNoOfRels() {
        var models = this.getRels
        var rels = []
        if (models != null) {
            models.forEach((model) => {
            rels = Object.values(model.relationships)
            if (rels != null) {
                rels = rels.filter(rel => rel == 'HasOne' || rel == 'HasMany')
            }
          })  
        }
        return rels.length
    }
  }
}
</script>
