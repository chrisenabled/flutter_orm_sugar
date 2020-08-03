<template>
    <q-page class="row q-ma-md justify-center">
        <div class="self-center">
            <div v-if="loading">
                <q-spinner-cube color="orange" size="5.5em"></q-spinner-cube>
            </div>

            <div v-if="error" class="error">
                <q-banner rounded inline-actions class="text-white bg-red">
                    <q-icon name="ti-face-sad"></q-icon> &nbsp; {{ error }}
                    <template v-slot:action @click="fetchConfig">
                        <q-btn flat color="white" label="Retry" />
                    </template>
                </q-banner>
            </div>
        </div>
        <div v-if="config" class="column col q-gutter-y-lg">
            <div class="row justify-center q-gutter-sm">
                <q-card v-if="Object.keys(config.repositories).length > 0"
                    class="my-card text-white col-md col-xs-12" 
                    style="background: linear-gradient(to bottom, #1FD2E6, #37C0EE)">
                    <q-card-section class="flex flex-center">
                        <q-avatar color="white" class="shadow-2" text-color="cyan-3" icon="ti-server" />
                    </q-card-section>
                    <q-card-section class="q-pt-none flex flex-center text-h4 text-weight-bolder">
                        {{Object.keys(config['repositories']).length}}
                        <span class="text-caption">&nbsp;DB</span>
                    </q-card-section>
                    <q-card-section class="q-pt-none flex flex-center 
                    text-caption text-light-blue-1 text-weight-bold">
                        Databases
                    </q-card-section>
                </q-card>
                <q-card v-if="Object.keys(config.models).length > 0"
                    class="my-card text-white col-md col-xs-12" 
                    style="background: linear-gradient(to bottom, #FFA291, #FE2051)">
                    <q-card-section class="flex flex-center">
                        <q-avatar color="white" class="shadow-2" text-color="red-3" icon="ti-layers-alt" />
                    </q-card-section>
                    <q-card-section class="q-pt-none flex flex-center text-h4 text-weight-bolder">
                        {{Object.keys(config['models']).length}}
                        <span class="text-caption">&nbsp;OB</span>
                    </q-card-section>
                    <q-card-section class="q-pt-none flex flex-center text-caption text-red-1 text-weight-bold">
                        Objects
                    </q-card-section>
                </q-card>
                <q-card v-if="getRels != null"
                    class="my-card text-white col-md col-xs-12" 
                    style="background: linear-gradient(to bottom, #3BB993, #0CA463)">
                    <q-card-section class="flex flex-center">
                        <q-avatar color="white" class="shadow-2" text-color="green-4" icon="ti-link" />
                    </q-card-section>
                    <q-card-section class="q-pt-none flex flex-center text-h4 text-weight-bolder">
                        {{getNoOfRels()}}
                        <span class="text-caption">&nbsp;RL</span>
                    </q-card-section>
                    <q-card-section class="q-pt-none flex flex-center text-caption text-green-1 text-weight-bold">
                        Relations
                    </q-card-section>
                </q-card>
            </div>
            <div v-if="Object.keys(config.repositories).length" class="row q-gutter-md justify-center">
                <q-card v-if="config.repositories.firestore" class="text-white col-md col-xs-5">
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
                <q-card v-if="config.repositories.sqlite" class="text-white col-md col-xs-5">
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
                <q-card v-if="config.repositories.api" class="col-md col-xs-5">
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
                <q-card v-if="config.repositories.sharedPref" class="text-white col-md col-xs-5">
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
            <div v-if="Object.keys(config.models).length > 0" class="q-pa-md">
                <q-table
                    class="my-sticky-header-table"
                    title="Objects Stats"
                    :data="Object.values(config.models)"
                    :columns="columns"
                    row-key="name"
                    primary
                    table-header-class="bg-blue-1"
                    color="white"   
                >
                    <template v-slot:body="props">
                        <q-tr :props="props">
                            <q-td key="name" :props="props" >
                                <q-icon class="text-pink" name="ti-layers-alt"></q-icon> 
                                &nbsp; {{ props.row.modelName }}
                            </q-td>
                            <q-td key="fieldsCount" :props="props">
                                <q-badge color="blue-5">
                                {{ props.row.modelFields.length }}
                                </q-badge>
                            </q-td>
                            <q-td key="name" :props="props">
                                <q-icon name="ti-server" class="text-cyan"></q-icon> 
                                &nbsp; {{ props.row.repository }}
                            </q-td>
                            <q-td key="repoName" :props="props">
                                <q-badge color="deep-purple-10">
                                {{ props.row.repoName }}
                                </q-badge>
                            </q-td>
                            <q-td key="name" :props="props">
                                <q-icon name="ti-link" class="text-green" ></q-icon> &nbsp; 
                                    {{ Object.keys(props.row.relationships).length }}
                                </q-td>
                        </q-tr>
                    </template>
                </q-table>
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
          label: 'Object',
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
          label: 'No. of Relations',
          align: 'left',
          field: row => Object.keys(row.relationships).length,
          sortable: true
        }
      ],
    }
  },
  mounted: function () {
    this.$nav.current = 'Dashboard'
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
    getDbUsage(dbName) {
        modelsArr = Object.values(this.$store.config.data['models'])
        count = modelsArr.length
        noOfModels = modelsArr.filter((model) => model['repository'] == dbName)
        if (noOfModels == 0) return 0
        return (noOfModels.length/count).toFixed(2) || 0
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
