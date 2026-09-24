// Tests the run() dispatcher exactly as SKILL.md prints it: node test_run.mjs
import { readFileSync } from 'node:fs'
import assert from 'node:assert/strict'

const md = readFileSync(new URL('../SKILL.md', import.meta.url), 'utf8')
const src = md.match(/```js\n([\s\S]*?)```/)[1]
const calls = []
const agent = (prompt, opts) => (calls.push({ prompt, opts }), 'ok')
const run = new Function('agent', `${src}; return run`)(agent)

const throws = (name, f, re) => { assert.throws(f, re, name); console.log(`ok   ${name}`) }
const passes = (name, f) => { f(); console.log(`ok   ${name}`) }

throws('no model is refused (the silent default)', () => run('build', 'p', { effort: 'low' }), /model must be/)
throws('no options at all is refused', () => run('build', 'p'), /model must be/)
throws('fable is refused', () => run('gate', 'p', { model: 'fable', effort: 'low' }), /got fable/)
throws('a full model id is refused', () => run('build', 'p', { model: 'claude-opus-5-5', effort: 'low' }), /model must be/)
throws('opus without effort is refused', () => run('build', 'p', { model: 'opus' }), /name an effort/)
throws('sonnet without effort is refused', () => run('judge', 'p', { model: 'sonnet' }), /name an effort/)

passes('opus/low goes through with model, effort, label and pass-through opts', () => {
  run('build', 'P', { model: 'opus', effort: 'low', phase: 'R2', schema: { type: 'object' } })
  assert.deepEqual(calls.at(-1), { prompt: 'P', opts: { model: 'opus', effort: 'low', label: 'build opus/low', phase: 'R2', schema: { type: 'object' } } })
})
passes('haiku needs no effort and sends none', () => {
  run('capture', 'P', { model: 'haiku' })
  assert.deepEqual(calls.at(-1).opts, { model: 'haiku', label: 'capture haiku/-' })
})
passes('returns what agent() returns', () => assert.equal(run('gate', 'P', { model: 'opus', effort: 'xhigh' }), 'ok'))
console.log('all passed')
