import os
from crewai import Agent, Task, Crew, LLM

os.environ["ANTHROPIC_BASE_URL"] = "https://cloud.infini-ai.com/maas/coding"
os.environ["ANTHROPIC_AUTH_TOKEN"] = "sk-cp-mcbhmyjwish2iwbl"
os.environ["CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC"] = "1"
os.environ["ANTHROPIC_API_KEY"] = ""
os.environ["ANTHROPIC_DEFAULT_HAIKU_MODEL"] = "glm-5"
os.environ["ANTHROPIC_DEFAULT_SONNET_MODEL"] = "glm-5"
os.environ["ANTHROPIC_DEFAULT_OPUS_MODEL"] = "glm-5"

llm = LLM(
    model="glm-5",
    base_url="https://cloud.infini-ai.com/maas/coding/v1",
    api_key="sk-cp-mcbhmyjwish2iwbl",
    temperature=0.1,
)

cocotb_agent = Agent(
    role="Cocotb Verification Engineer",
    goal="Create comprehensive cocotb-based verification with verilator to achieve 90%+ code coverage",
    backstory="""You are an expert verification engineer specializing in cocotb and verilator.
    You have deep knowledge of Python-based testbench creation, coverage-driven verification,
    and waveform analysis. Your testbenches are well-structured and achieve high coverage.""",
    llm=llm,
    verbose=True,
)

task = Task(
    description="""Create a comprehensive cocotb verification environment for APB UART using verilator.

Requirements:
1. Convert existing SystemVerilog testbench to cocotb Python testbench
2. Use verilator as the simulator with --coverage flag
3. Create comprehensive tests covering:
   - APB read/write transactions
   - UART TX transmission
   - UART RX reception
   - FIFO overflow/underflow
   - Interrupt generation
   - Register access
   - Corner cases
4. Use cocotb coverage module to track line/branch coverage
5. Generate coverage report with >90% coverage goal

Files to use:
- RTL: apb_uart_crew/rtl/*.v
- Output: apb_uart_crew/verification/cocotb/

Run make in verification/cocotb/ to compile and run tests.""",
    expected_output="Complete cocotb testbench with 90%+ coverage report",
    agent=cocotb_agent,
)

crew = Crew(agents=[cocotb_agent], tasks=[task], verbose=True)

print("Starting Cocotb Verification Task...")
print("=" * 60)
result = crew.kickoff()
print("=" * 60)
print("TASK COMPLETED")
print("=" * 60)
print(result)
