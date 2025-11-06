import { spawn } from 'child_process'
import { readFileSync, writeFileSync, existsSync, mkdtempSync, unlinkSync } from 'fs'
import path from 'path'
import { tmpdir } from 'os'
import { fileURLToPath } from 'url'

// Function to handle code formatting with ruff
// Note: The bridge already converts relative URIs to absolute URIs before calling this function
export async function handleFormatting(msg: any, writer: any, wsWriter: any, ruffPath: string) {
    try {
        console.log('🎨 Formatting request intercepted, handling with ruff...')

        const textDocument = msg.params?.textDocument
        const uri = textDocument?.uri

        if (!uri) {
            console.error('❌ No URI in formatting request')
            wsWriter.write({
                jsonrpc: '2.0',
                id: msg.id,
                error: {
                    code: -32602,
                    message: 'Invalid params: missing textDocument.uri'
                }
            })
            return
        }

        // Convert URI to file path (URI is already absolute from the bridge)
        console.log(`📥 Received URI: ${uri}`)
        
        let filePath: string
        try {
            filePath = fileURLToPath(uri)
            console.log(`🔍 File path: ${filePath}`)
        } catch (err) {
            console.error(`❌ Failed to convert URI to path:`, err)
            wsWriter.write({
                jsonrpc: '2.0',
                id: msg.id,
                error: {
                    code: -32602,
                    message: 'Invalid file URI'
                }
            })
            return
        }

        // Check if ruff exists
        if (!existsSync(ruffPath)) {
            console.error('❌ Ruff binary not found at:', ruffPath)
            wsWriter.write({
                jsonrpc: '2.0',
                id: msg.id,
                error: {
                    code: -32000,
                    message: 'Ruff binary not available'
                }
            })
            return
        }

        // For full document formatting, we need to format the file on disk
        // In a real implementation, you might want to handle range formatting differently
        const isRangeFormatting = msg.method === 'textDocument/rangeFormatting'
        const isFullFormatting = msg.method === 'textDocument/formatting'

        if (isRangeFormatting) {
            // For range formatting, we need to read the file, apply changes to the range,
            // write to temp file, format, then extract the formatted range
            console.log('📝 Range formatting not fully implemented yet, falling back to full document formatting')
        }

        if (!isFullFormatting && !isRangeFormatting) {
            console.log('⚠️ Unsupported formatting method:', msg.method)
            // Let Pyright handle other formatting methods
            writer.write(msg)
            return
        }

        // Create a temporary file for formatting
        const tempDir = mkdtempSync(path.join(tmpdir(), 'ruff-format-'))
        const tempFile = path.join(tempDir, 'temp.py')

        try {
            // Read the current file content
            // Note: For formatting, we should use the file on disk as the source of truth
            let fileContent: string
            if (existsSync(filePath)) {
                fileContent = readFileSync(filePath, 'utf-8')
                console.log(`📖 Read file from disk: ${filePath}`)
                console.log(`   Content length: ${fileContent.length} chars`)
            } else {
                // If file doesn't exist, use empty content or content from params
                fileContent = msg.params?.textDocument?.text || ''
                console.log(`⚠️ File not found on disk, using params or empty content`)
            }

            // Write content to temp file
            writeFileSync(tempFile, fileContent)
            console.log(`💾 Wrote content to temp file: ${tempFile}`)

            // Run ruff format on the temp file
            const ruff = spawn(ruffPath, ['format', tempFile], {
                cwd: tempDir,
                stdio: ['pipe', 'pipe', 'pipe']
            })

            let stdout = ''
            let stderr = ''

            ruff.stdout.on('data', (data) => {
                stdout += data.toString()
            })

            ruff.stderr.on('data', (data) => {
                stderr += data.toString()
            })

            await new Promise((resolve, reject) => {
                ruff.on('close', (code) => {
                    console.log(`🔧 Ruff process exited with code: ${code}`)
                    if (stderr) console.log(`   stderr: ${stderr}`)
                    if (stdout) console.log(`   stdout: ${stdout}`)
                    
                    if (code === 0) {
                        resolve(void 0)
                    } else {
                        reject(new Error(`Ruff exited with code ${code}: ${stderr}`))
                    }
                })
                ruff.on('error', reject)
            })

            // Read the formatted content
            const formattedContent = readFileSync(tempFile, 'utf-8')

            // Calculate the text edits - replace entire document
            const lines = fileContent.split('\n')
            const lineCount = lines.length
            const hasTrailingNewline = lines[lineCount - 1] === ''

            // Calculate the correct end position for full document replacement
            let endLine: number
            let endCharacter: number

            if (hasTrailingNewline && lineCount >= 2) {
                // Document ends with newline, end at the end of the last content line
                endLine = lineCount - 2
                endCharacter = lines[lineCount - 2].length
            } else {
                // Document doesn't end with newline, end at the end of the last line
                endLine = lineCount - 1
                endCharacter = lines[lineCount - 1].length
            }

            const edits = [{
                range: {
                    start: { line: 0, character: 0 },
                    end: { line: endLine, character: endCharacter }
                },
                newText: formattedContent
            }]

            console.log('✅ Formatting completed successfully')
            console.log(`📤 Sending response with ${edits.length} edit(s)`)
            console.log(`   Range: (${edits[0].range.start.line},${edits[0].range.start.character}) -> (${edits[0].range.end.line},${edits[0].range.end.character})`)
            console.log(`   New text length: ${formattedContent.length} chars`)
            console.log(`   First 100 chars: ${formattedContent.substring(0, 100)}`)

            // Send the response
            const response = {
                jsonrpc: '2.0',
                id: msg.id,
                result: edits
            }
            
            console.log('📨 Response object:', JSON.stringify(response).substring(0, 500))
            wsWriter.write(response)

        } finally {
            // Clean up temp files
            try {
                if (existsSync(tempFile)) unlinkSync(tempFile)
                // Note: tempDir cleanup would be handled by OS, but in production you might want to clean it up
            } catch (err) {
                console.warn('⚠️ Failed to clean up temp file:', err)
            }
        }

    } catch (error) {
        console.error('❌ Formatting error:', error)
        wsWriter.write({
            jsonrpc: '2.0',
            id: msg.id,
            error: {
                code: -32000,
                message: `Formatting failed: ${error.message}`
            }
        })
    }
}
