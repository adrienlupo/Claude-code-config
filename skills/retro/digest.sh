#!/bin/sh
# usage: digest.sh <session.jsonl> [cut-timestamp]  -> digest on stdout. Everything at or after cut-timestamp is ignored.
S=$1; CUT=${2:-9999}; SID=$(basename "$S" .jsonl); DIR=$(dirname "$S")
TS='sub("\\.[0-9]+Z$";"Z")|fromdate'
echo "# session $SID"
echo "# file    $S"
echo "## time:  $(jq -rs --arg cut "$CUT" '[.[] | select(.timestamp != null and .timestamp < $cut) | .timestamp] | sort | . as $t
  | [range(1; length) | ($t[.] | '"$TS"') - ($t[.-1] | '"$TS"')]
  | "span=\(if ($t|length)>1 then ((($t[-1]|'"$TS"')-($t[0]|'"$TS"'))/60|floor) else 0 end)m active=\(([.[]|select(.<=300)]|add//0)/60|floor)m gaps(>5m)=\([.[]|select(.>300)]|length)"' "$S")"
echo "## turns: user=$(jq -r --arg c "$CUT" 'select(.type=="user" and .timestamp<$c) | .message.content | if type=="string" then . elif (.[0].type? // "")=="text" then .[0].text else empty end | gsub("\n";" ")' "$S" | grep -v -e '^<local-command' -e '^<command-' -e '^Base directory for this skill' -e '<task-notification>' | wc -l | tr -d ' ')  assistant=$(jq -r --arg c "$CUT" 'select(.type=="assistant" and .timestamp<$c)|1' "$S" | wc -l | tr -d ' ')  output_tokens=$(jq -r --arg c "$CUT" 'select(.type=="assistant" and .timestamp<$c) | .message.usage.output_tokens // 0' "$S" | awk '{s+=$1} END{print s+0}')"
echo "## tools:"; jq -r --arg c "$CUT" 'select(.type=="assistant" and .timestamp<$c) | .message.content[]? | select(.type=="tool_use") | .name' "$S" | sort | uniq -c | sort -rn | awk '{printf "   %s x%s\n",$2,$1}'
echo "## tool errors: $(jq -r --arg c "$CUT" 'select(.type=="user" and .timestamp<$c) | .message.content[]? | select(.type=="tool_result" and .is_error==true) | 1' "$S" | wc -l | tr -d ' ')"
echo "## skills invoked:"; { grep -o '<command-name>/[^<]*' "$S" | sed 's/<command-name>//'; jq -r --arg c "$CUT" 'select(.type=="assistant" and .timestamp<$c) | .message.content[]? | select(.type=="tool_use" and .name=="Skill") | "/\(.input.skill)"' "$S"; } | grep -v '^/retro$' | sort | uniq -c | awk '{printf "   %s x%s\n",$2,$1}'
echo "## files read 3+ times:"; jq -r --arg c "$CUT" 'select(.type=="assistant" and .timestamp<$c) | .message.content[]? | select(.type=="tool_use" and .name=="Read") | .input.file_path' "$S" | sort | uniq -c | awk '$1>=3{printf "   x%s %s\n",$1,$2}'
echo "## user prompts (line | time | gap-before | text):"
jq -r --arg c "$CUT" 'select(.timestamp != null and .timestamp<$c) | select(.type=="user" or .type=="assistant") | {t:.type, ts:.timestamp, txt:(if .type=="user" then (.message.content | if type=="string" then . elif (.[0].type? // "")=="text" then .[0].text else null end) else null end)}' "$S" \
 | jq -rs '. as $a | [range(0;length) | select($a[.].t=="user" and $a[.].txt!=null and ($a[.].txt|test("^<local-command|<task-notification>")|not)) | {i:., ts:$a[.].ts, gap:(if .>0 then (($a[.].ts|'"$TS"')-($a[.-1].ts|'"$TS"')) else 0 end), txt:($a[.].txt|gsub("\n";" ")|.[0:220])}] | .[] | "   \(.i) | \(.ts[0:16]) | +\(.gap/60|floor)m | \(.txt)"'
echo "## gaps > 5 min (what ended the gap):"
jq -r --arg c "$CUT" 'select(.timestamp != null and .timestamp<$c) | select(.type=="user" or .type=="assistant") | {t:.type, ts:.timestamp, kind:(if .type=="assistant" then "assistant" elif ((.message.content|type)=="array" and (.message.content[0].type? // "")=="tool_result") then "tool-wait" else "user" end)}' "$S" | jq -rs '. as $a | [range(1;length) | {gap:(($a[.].ts|'"$TS"')-($a[.-1].ts|'"$TS"')), at:$a[.].ts[0:16], next:$a[.].kind}] | .[] | select(.gap>300) | "   +\(.gap/60|floor)m until \(.at) (\(.next))"'
W="$DIR/$SID/subagents"
if [ -d "$W" ]; then
  echo "## subagents (id model minutes tools output-tokens errors | prompt start):"
  for wf in $( { find "$W" -type d -name 'wf_*'; echo "$W"; } | while read d; do N=$(ls "$d"/agent-*.jsonl 2>/dev/null | wc -l | tr -d ' '); [ "$N" = 0 ] && continue; echo "$(cat "$d"/agent-*.jsonl | jq -r '.timestamp // empty' | sort | head -1) $d"; done | sort | awk '{print $2}'); do
    N=$(ls "$wf"/agent-*.jsonl | wc -l | tr -d ' ')
    echo "### $(basename "$wf")  agents=$N  $(cat "$wf"/agent-*.jsonl | jq -r '.timestamp // empty' | sort | sed -n '1p;$p' | cut -c1-16 | tr '\n' ' ')"
    for a in "$wf"/agent-*.jsonl; do
      jq -rs '{id:(input_filename|split("/")[-1]|.[6:14]), model:([.[]|select(.type=="assistant")|.message.model]|unique|map(sub("claude-";"")|sub("-[0-9]{8}$";""))|join(",")), tools:([.[]|select(.type=="assistant")|.message.content[]?|select(.type=="tool_use")]|length), out:([.[]|select(.type=="assistant")|.message.usage.output_tokens//0]|add//0), min:(([.[]|.timestamp//empty]|sort|if length>1 then ((.[-1]|'"$TS"')-(.[0]|'"$TS"')) else 0 end)/60|floor), err:([.[]|select(.type=="user")|.message.content[]?|select(.type=="tool_result" and .is_error==true)]|length), prompt:((first(.[]|select(.type=="user")|.message.content|if type=="string" then . else (.[0].text//"") end)//"")|gsub("\n";" ")|.[0:110])} | "   \(.id) \(.model) \(.min)m tools=\(.tools) out=\(.out) err=\(.err) | \(.prompt)"' "$a"
    done
  done
fi
